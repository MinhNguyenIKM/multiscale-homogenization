C these subroutines allow to load and call the function defined by the parameters
C of the "label//_dk_NNs.dat" file saved by RS_HDMR_NN.m
C if multiple stages (dk) are used (see Eq.(8) of the article), simply sum the functions for all k
C
C function call: f=xNNimport(x,xLW21,xLW32,xLW43,b2,b3,b4,nD,nDterm,Nterms,Nneurons)
C
C where x is a D-dimensional vector of coordinates 
C The rest of the input are PES parameters, see below
C
C The following variables have to be declared in the calling program:
C
C integer nD,nDterm,Nterms,Nneurons,neuroncode
C real*8 xminp,xmaxp,xmint,xmaxt
C dimension xminp(30),xmaxp(30) ! change 30 to a larger number if your D>30
C REAL*8,ALLOCATABLE::xLW21(:,:,:),xLW32(:,:,:),xLW43(:,:)
C REAL*8,ALLOCATABLE::b2(:,:),b3(:,:),b4(:,:)  
C REAL*8,ALLOCATABLE::x(:)
C common/NNparam/ xminp,xmaxp,xmint,xmaxt,nD,nDterm,Nterms,Nneurons,neuroncode
C
C Before a call to xNNimport, PES has to be initialised by :
C
C call load1(filename)
C ALLOCATE(xLW21(Nterms,nDterm,nD))
C ALLOCATE(xLW32(Nterms,Nneurons,nDterm))
C ALLOCATE(xLW43(Nterms,Nneurons),b2(Nterms,nDterm))
C ALLOCATE(b3(Nterms,Nneurons),b4(Nterms,1))   
C ALLOCATE(x(nD))  
C call load2(filename,xLW21,xLW32,xLW43,b2,b3,b4,nD,nDterm,Nterms,Nneurons)
C
C where filename is the name of the "label//_dk_NNs.dat" file saved by RS_HDMR_NN.m
C containing the PES parameters
C now the parameters are read into memory and the call to the function xNNimport can be made
C 
C**********************************************************************			

       ! this function computes a function fit by NNMMRedSeq_ini.m as
       ! a sum of neural networks 
       function xNNimport(x,xLW21,xLW32,xLW43,b2,b3,b4,
     1               nD1,nDterm1,Nterms1,Nneurons1) 
       IMPLICIT DOUBLE PRECISION (A-H,O-Z)        
       parameter (pic=3.1415926535898d0)
       integer nD,nDterm,Nterms,Nneurons,neuroncode
       integer nD1,nDterm1,Nterms1,Nneurons1 
       real*8 xminp,xmaxp,xmint,xmaxt, E
       dimension xminp(30),xmaxp(30)
       REAL*8,DIMENSION(Nterms1,nDterm1,nD1)::xLW21
       REAL*8,DIMENSION(Nterms1,Nneurons1,nDterm1)::xLW32     
       REAL*8,DIMENSION(Nterms1,Nneurons1)::xLW43 
       REAL*8,DIMENSION(Nterms1,nDterm1)::b2 
       REAL*8,DIMENSION(Nterms1,Nneurons1)::b3 
       REAL*8,DIMENSION(Nterms1,1)::b4 
       REAL*8,DIMENSION(nD1)::x,xn 
       REAL*8,DIMENSION(nDterm1)::xlayer2
       REAL*8,DIMENSION(Nneurons1)::xlayer3
       REAl*8,DIMENSION(1)::xlayer4
       common/NNparam/ xminp,xmaxp,xmint,xmaxt,nD,nDterm,Nterms,
     1                 Nneurons,neuroncode

          ! scale input x pn = 2*(p-minp)/(maxp-minp) - 1;
          do i=1,nD
             xn(i)=2d0*(x(i)-xminp(i))/(xmaxp(i)-xminp(i))-1d0             
          end do
          !write(*,*) "x=",x
          !write(*,*) "x=n",xn 

          ! calculate the function
          E=0d0
          do i=1,Nterms
             ! output of the 2nd, coord transform, layer
             do j=1,nDterm
                xlayer2(j)=b2(i,j)
                do k=1,nD
                   xlayer2(j)=xlayer2(j)+xLW21(i,j,k)*xn(k)
                end do
             end do
             ! write(*,*) "layer2=",xlayer2
             ! output of the 3rd, nonlinear, layer
             do j=1,Nneurons
                xlayer3(j)=b3(i,j)
                do k=1,nDterm
                   xlayer3(j)=xlayer3(j)+xLW32(i,j,k)*xlayer2(k)
                end do                
                xlayer3(j)=xneuron(xlayer3(j),neuroncode)
             end do 
             ! write(*,*) "layer3=",xlayer3
             ! output of the 4th layer = partial NN output
             xlayer4(1)=b4(i,1)
             do j=1,Nneurons
                xlayer4(1)=xlayer4(1)+xLW43(i,j)*xlayer3(j)
             end do
             E=E+xlayer4(1)  !or satlins(xlayer4(1))
          end do !  do i=1,Nterms

          ! scale back
          E=0.5d0*(E+1d0)*(xmaxt-xmint)+xmint  !  p = 0.5(pn+1)*(maxp-minp) + minp; 
       xNNimport=E       
       end ! NNimport

       subroutine load1(filename)
       IMPLICIT DOUBLE PRECISION (A-H,O-Z)
       character (len=100)::filename
       integer nD,nDterm,Nterms,Nneurons,neuroncode
       real*8 xminp,xmaxp,xmint,xmaxt
       dimension xminp(30),xmaxp(30)              
       common/NNparam/ xminp,xmaxp,xmint,xmaxt,nD,nDterm,Nterms,
     1                 Nneurons,neuroncode
          open(1,file=filename,status='old')
             read(1,*) nD,nDterm,Nterms,Nneurons,neuroncode           
             read(1,*) (xminp(j),j=1,nD)
             read(1,*) (xmaxp(j),j=1,nD)
             read(1,*) xmint, xmaxt             
          close(1)  
       end ! load1

       subroutine load2(filename,xLW21,xLW32,xLW43,b2,b3,b4,
     1                  nD,nDterm,Nterms,Nneurons)
       IMPLICIT DOUBLE PRECISION (A-H,O-Z)
       character (len=100)::filename
       integer nD,nDterm,Nterms,Nneurons
       REAL*8,DIMENSION(Nterms,nDterm,nD)::xLW21
       REAL*8,DIMENSION(Nterms,Nneurons,nDterm)::xLW32     
       REAL*8,DIMENSION(Nterms,Nneurons)::xLW43 
       REAL*8,DIMENSION(Nterms,nDterm)::b2 
       REAL*8,DIMENSION(Nterms,Nneurons)::b3 
       REAL*8,DIMENSION(Nterms,1)::b4    
       real*8,dimension(30)::dummy
       
          ! reread to position cursor
          open(1,file=filename,status='old')
             read(1,*) (dummy(j),j=1,5)           
             read(1,*) (dummy(j),j=1,nD)
             read(1,*) (dummy(j),j=1,nD)
             read(1,*) (dummy(j),j=1,2)

          ! read NN matrices          
             do i=1,Nterms
                ! read xLW21
                do j=1,nDterm                   
                   read(1,*) (xLW21(i,j,k),k=1,nD)
                   !write(*,*) (xLW21(i,j,k),k=1,nD)                   
                end do
                ! read xLW32
                do j=1,Nneurons                   
                   read(1,*) (xLW32(i,j,k),k=1,nDterm)
                   !write(*,*) (xLW32(i,j,k),k=1,nDterm)                   
                end do
                ! read xLW43
                do j=1,Nneurons                   
                   read(1,*) xLW43(i,j)
                   !write(*,*) xLW43(i,j)                   
                end do
                ! read b2
                do j=1,nDterm                   
                   read(1,*) b2(i,j)
                   !write(*,*) b2(i,j)                   
                end do
                ! read b3
                do j=1,nNeurons                   
                   read(1,*) b3(i,j)
                   !write(*,*) b3(i,j)                   
                end do
                ! read b4 
                read(1,*) b4(i,1)
                !write(*,*) b4(i,1) 
             end do ! do i=1,Nterms           
          close(1)

       end ! load2

       real*8 function xneuron(x,neuroncode)
       integer neuroncode
       real*8 x
          if (neuroncode.eq.1) then
             xneuron=2d0/(1d0+dexp(-2d0*x))-1d0  ! n = 2/(1+exp(-2*n))-1
          else if (neuroncode.eq.2) then
             xneuron=exp(x)
          end if
       end function xneuron 

       real*8 function satlins(x)
       real*8 x
          if (x.le.-1d0) then
             satlins=-1d0
          else if (x.ge.1d0) then
             satlins=1d0
          else
             satlins=x
          end if
       end function satlins