! This source code file was last time modified by Igor UA3DJY on 20190708
! All changes are shown in the patch file coming together with the full JTDX source code.

subroutine subtractft88(itone,f0,dt)

  !$ use omp_lib
  use ft8_mod1, only : dd8,cw,cfilt8,cref8
! NMAX=15*12000,NFFT=15*12000,NFRAME=1920*79
  parameter (NFFT=184320,NMAX=180000,NFRAME=151680)
  integer itone(79)

  nstart=dt*12000+1
!  call genft8refsig(itone,cref8,f0)
  call gen_ft8wavesub(itone,f0,cref8)
  do i=1,nframe
    id=nstart-1+i 
    if(id.ge.1.and.id.le.NMAX) then
      cfilt8(i)=dd8(id)*conjg(cref8(i))
    else
      cfilt8(i)=0.0
    endif
  enddo
  cfilt8(nframe+1:)=0.0
  call four2a(cfilt8,nfft,1,-1,1)
  cfilt8(1:nfft)=cfilt8(1:nfft)*cw(1:nfft)
  call four2a(cfilt8,nfft,1,1,1)
!$omp critical(subtraction)
  do i=1,nframe
     j=nstart+i-1
     if(j.ge.1 .and. j.le.NMAX) dd8(j)=dd8(j)-2*REAL(cfilt8(i)*cref8(i))
  enddo
!$omp end critical(subtraction)
!$OMP FLUSH (dd8)

  return
end subroutine subtractft88
