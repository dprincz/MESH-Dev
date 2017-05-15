!>
!> Author: Ala Bahrami
!> Date of creation : 01 March 2017
!> last modified    : 01 March 2017
!> written for Ph.D Thesis
!> Type:   f90
!>
module file_variables

    implicit none

    integer (kind = 4) :: N_x, N_y, n_e, N_forcepert, N_ens, n


    real (kind = 4) :: dx, dy, lambda_x, lambda_y, variance

    ! temporal variables
    real :: dtstep, tcorr

    !real (kind = 8), allocatable, dimension(:,:) :: field1, field2
    !integer, parameter :: N1= 49
    !integer, parameter :: N2= 113

    !double precision, dimension(N1 , N2) :: rfield, rfield2
    double precision, dimension(: , :), allocatable :: rfield, rfield2
    !double precision, dimension(:,:), allocatable :: field1, field2
    !double precision, dimension(:,:), allocatable :: rfield, rfield2


    ! local variables
    integer (kind = 4) :: N_x_fft, N_y_fft, N_x_fft2

    real :: dkx, dky, theta, ran_num

    real, parameter :: MY_PI = 3.14159265


    !include "fftw3.f90"


    ! Variables for FFT calculation
    !double precision , dimension(:,:), allocatable :: field1_fft, field2_fft
    double complex , dimension(:,:), allocatable :: field1_fft, field2_fft


    ! allocatble variable for FFT Inverse
    !complex (kind = 8), dimension(:,:), allocatable :: field1_fft_inv, field2_fft_inv
    double complex, dimension(:,:), allocatable :: field1_fft_inv, field2_fft_inv

    ! local variable used in the get_fft_grid

    ! specify by how many correlation lengths the fft grid must be
    ! be larger than the grid2cat grid
    real, parameter :: mult_of_xcorr = 2.
    real, parameter :: mult_of_ycorr = 2.

    ! random variables
    integer :: RSEEDCONST
    integer :: NRANDSEED2
    integer, parameter :: NRANDSEED = 35
    integer, dimension(NRANDSEED) :: rseed

    ! FFT variables
    integer (kind = 8) plan_forward

    ! variable whicha are used in producing the forcing perturbation
    logical :: initialize

    integer, dimension(:),   allocatable  :: ens_id
    integer, dimension(:,:), allocatable  :: Forcepert_rseed

    real, dimension(:,:,:,:), allocatable :: Forcepert
    real, dimension (:,:,:) ,allocatable  :: Forcepert_vect
    real, dimension(:,:,:,:), allocatable :: Forcepert_ntrmdt

    !type(forcepert_param_type), dimension(:), pointer :: forcepert_param
    ! Timing stamps variables



    save

end module