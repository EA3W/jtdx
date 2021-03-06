! last time modified by Igor UA3DJY on 20200209

subroutine sync8(nfa,nfb,syncmin,nfqso,candidate,ncand,jzb,jzt,swl,ipass,lqsothread)

  use ft8_mod1, only : dd8,windowx,facx,icos7,lagcc,lagccbail,nfawide,nfbwide
  include 'ft8_params.f90'
  complex cx(0:NH1)
  real s(NH1,NHSYM)
  real x(NFFT1)
  real sync2d(NH1,jzb:jzt)
  real red(NH1)
  real candidate0(3,250)
  real candidate(3,260)
  real freq
  integer jpeak(NH1)
  integer indx(NH1)
  integer ii(1)
  integer, intent(in) :: nfa,nfb,nfqso,jzb,jzt,ipass
  logical(1), intent(in) :: swl,lqsothread
  equivalence (x,cx)

! Compute symbol spectra, stepping by NSTEP steps.  
  tstep=0.04 ! NSTEP/12000.0                         
  df=3.125 ! 12000.0/NFFT1 , Hz

  if(ipass.eq.1 .or. ipass.eq.4 .or. ipass.eq.7) then
     do j=1,NHSYM
        ia=(j-1)*NSTEP + 1
        ib=ia+NSPS-1
        x(1:759)=0.
        if(j.ne.1) then; x(760:960)=dd8(ia-201:ia-1)*windowx(200:0:-1); else; x(760:960)=0.; endif
        x(961:2880)=facx*dd8(ia:ib); x(961)=x(961)*1.9; x(2880)=x(2880)*1.9
        if(j.ne.NHSYM) then; x(2881:3081)=dd8(ib+1:ib+201)*windowx; else; x(2881:3081)=0.; endif
        x(3082:)=0.
        call four2a(x,NFFT1,1,-1,0)              !r2c FFT
        do i=1,NH1
           s(i,j)=SQRT(real(cx(i))**2 + aimag(cx(i))**2)
        enddo
     enddo
  endif
  if(ipass.eq.2 .or. ipass.eq.5 .or. ipass.eq.8) then
     do j=1,NHSYM
        ia=(j-1)*NSTEP + 1
        ib=ia+NSPS-1
        x(1:759)=0.
        if(j.ne.1) then; x(760:960)=dd8(ia-201:ia-1)*windowx(200:0:-1); else; x(760:960)=0.; endif
        x(961:2880)=facx*dd8(ia:ib); x(961)=x(961)*1.9; x(2880)=x(2880)*1.9
        if(j.ne.NHSYM) then; x(2881:3081)=dd8(ib+1:ib+201)*windowx; else; x(2881:3081)=0.; endif
        x(3082:)=0.
        call four2a(x,NFFT1,1,-1,0)              !r2c FFT
        do i=1,NH1
           s(i,j)=real(cx(i))**2 + aimag(cx(i))**2
        enddo
     enddo
  endif
  if(ipass.eq.3 .or. ipass.eq.6 .or. ipass.eq.9) then
     do j=1,NHSYM
        ia=(j-1)*NSTEP + 1
        ib=ia+NSPS-1
        x(1:759)=0.
        if(j.ne.1) then; x(760:960)=dd8(ia-201:ia-1)*windowx(200:0:-1); else; x(760:960)=0.; endif
        x(961:2880)=facx*dd8(ia:ib); x(961)=x(961)*1.9; x(2880)=x(2880)*1.9
        if(j.ne.NHSYM) then; x(2881:3081)=dd8(ib+1:ib+201)*windowx; else; x(2881:3081)=0.; endif
        x(3082:)=0.
        call four2a(x,NFFT1,1,-1,0)              !r2c FFT
        do i=1,NH1
           s(i,j)=abs(real(cx(i))) + abs(aimag(cx(i)))
        enddo
     enddo
  endif

  ia=max(1,nint(nfa/df)); ib=max(1,nint(nfb/df)); iaw=max(1,nint(nfawide/df)); ibw=max(1,nint(nfbwide/df))
  nssy=4 ! NSPS/NSTEP   ! # steps per symbol
  nssy36=144 ! nssy*36
  nssy72=288 ! nssy*72
  nfos=2 ! NFFT1/NSPS   ! # frequency bin oversampling factor
  jstrt=12.5 ! 0.5/tstep

  if(lagcc .and. .not.lagccbail) then
    nfos6=12 ! nfos*6
    do j=jzb,jzt
      do i=iaw,ibw
        ta=0.; tb=0.; tc=0.; t0a=0.; t0b=0.; t0c=0.
        do n=0,6
          k=j+jstrt+nssy*n
          if(k.ge.1.and.k.le.NHSYM) then
            ta=ta + s(i+nfos*icos7(n),k); t0a=t0a + sum(s(i:i+nfos6:nfos,k))
          endif
          tb=tb + s(i+nfos*icos7(n),k+nssy36); t0b=t0b + sum(s(i:i+nfos6:nfos,k+nssy36))
          if(k+nssy72.le.NHSYM) then
            tc=tc + s(i+nfos*icos7(n),k+nssy72); t0c=t0c + sum(s(i:i+nfos6:nfos,k+nssy72))
          endif
        enddo
        t=ta+tb+tc; t0=t0a+t0b+t0c; t0=(t0-t)/6.0; if(t0.lt.1e-8) t0=1.0 ! safe division
        sync_abc=t/t0
        t=tb+tc; t0=t0b+t0c; t0=(t0-t)/6.0; if(t0.lt.1e-8) t0=1.0 ! safe division
        sync_bc=t/t0
        sync2d(i,j)=max(sync_abc,sync_bc)
      enddo
    enddo
  else
    nfos6=15 ! 16i spec bw -1 
    do j=jzb,jzt
      do i=iaw,ibw
        ta=0.; tb=0.; tc=0.; t0a=0.; t0b=0.; t0c=0.
        do n=0,6
          k=j+jstrt+nssy*n
          if(k.ge.1.and.k.le.NHSYM) then
            ta=ta + s(i+nfos*icos7(n),k); t0a=t0a + sum(s(i:i+nfos6,k))
          endif
          tb=tb + s(i+nfos*icos7(n),k+nssy36); t0b=t0b + sum(s(i:i+nfos6,k+nssy36))
          if(k+nssy72.le.NHSYM) then
            tc=tc + s(i+nfos*icos7(n),k+nssy72); t0c=t0c + sum(s(i:i+nfos6,k+nssy72))
          endif
        enddo
        t=ta+tb+tc; t0=t0a+t0b+t0c; t0=(t0-t*2)/42.0; if(t0.lt.1e-8) t0=1.0 ! safe division
        sync_abc=t/(7.0*t0)
        sync2d(i,j)=sync_abc
      enddo
    enddo
  endif

  red=0.
  do i=iaw,ibw
     ii=maxloc(sync2d(i,jzb:jzt)) - 1 + jzb
     j0=ii(1)
     jpeak(i)=j0
     red(i)=sync2d(i,j0)
!     write(52,3052) i*df,red(i),db(red(i))
!3052 format(3f12.3)
  enddo

  iz=ibw-iaw+1
  call indexx(red(iaw:ibw),iz,indx)
  ibase=indx(max(1,nint(0.40*iz))) - 1 + iaw ! max is workaround to prevent indx getting out of bounds
  base=red(ibase)
  if(base.lt.1e-8) base=1.0 ! safe division
  red=red/base

  candidate0=0.; k=0; iz=ib-ia+1
  call indexx(red(ia:ib),iz,indx)
  do i=1,iz
     n=ia + indx(iz+1-i) - 1
     freq=n*df
     if(abs(freq-nfqso).gt.3.0) then
        if (red(n).lt.syncmin) cycle
     else
        if (red(n).lt.1.1) cycle
     endif
     if(k.lt.250) then; k=k+1; else; exit; endif
! being sorted by sync
     candidate0(1,k)=freq
     candidate0(2,k)=(jpeak(n)-1)*tstep
     candidate0(3,k)=red(n)
  enddo
  ncand=k

  fdif0=4.0; if(swl) fdif0=3.0
!  xdtdelta=0.0

! save sync only to the best of near-dupe freqs 
  do i=1,ncand
     if(i.ge.2) then
        do j=1,i-1
           fdiff=abs(candidate0(1,i)-candidate0(1,j))
!           xdtdelta=abs(candidate0(2,i))-abs(candidate0(2,j)) !!!
!           if(abs(fdiff).lt.fdif0 .and. xdtdelta.lt.0.1) then !!!
           if(fdiff.lt.fdif0 .and. abs(candidate0(1,i)-nfqso).gt.3.0) then
              if(candidate0(3,i).ge.candidate0(3,j)) candidate0(3,j)=0.
              if(candidate0(3,i).lt.candidate0(3,j)) candidate0(3,i)=0.
           endif
        enddo
!        write(*,3001) i,candidate0(1,i-1),candidate0(1,i),candidate0(3,i-1),  &
!             candidate0(3,i)
!3001    format(i2,4f8.1)
     endif
  enddo
  
! Sort by sync
  call indexx(candidate0(3,1:ncand),ncand,indx)
! Sort by frequency 
!  call indexx(candidate0(1,1:ncand),ncand,indx)
  k=1
!Put nfqso at top of list and apply lowest sync threshold for nfqso
  fprev=5004.
  do i=ncand,1,-1
     j=indx(i)
     if(abs(candidate0(1,j)-nfqso).le.3.0 .and. candidate0(3,j).ge.1.1 .and. abs(candidate0(1,j)-fprev).gt.3.0) then
        candidate(1,k)=candidate0(1,j)
        candidate(2,k)=candidate0(2,j)
        candidate(3,k)=candidate0(3,j)
        fprev=candidate0(1,j)
        k=k+1
     endif
  enddo

!put virtual candidates for FT8S decoder
  if(lqsothread) then
    candidate(1,k)=float(nfqso)
    candidate(2,k)=5.0 ! xdt
    candidate(3,k)=0.0 ! sync
    k=k+1
    candidate(1,k)=float(nfqso)
    candidate(2,k)=-5.0
    candidate(3,k)=0.0
    k=k+1
  endif

  do i=ncand,1,-1
     j=indx(i)
     if(abs(candidate0(1,j)-nfqso).gt.3.0) then; syncmin1=syncmin; else; syncmin1=1.1; endif
     if(candidate0(3,j) .ge. syncmin1) then
       candidate(1,k)=candidate0(1,j)
       candidate(2,k)=candidate0(2,j)
       candidate(3,k)=candidate0(3,j)
       k=k+1
       if(k.gt.260) exit 
     endif
  enddo
  ncand=k-1

  return
end subroutine sync8
