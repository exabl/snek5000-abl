      program main
          implicit none

          include 'mpif.h'
          integer error
          integer mpi_rank
          integer mpi_size
          double precision wtime
          real r
          integer :: seed(8), i
c     
c      Initialize MPI.
c     
          call MPI_Init ( error )
c     
c      Get the number of processes.
c     
          call MPI_Comm_size ( MPI_COMM_WORLD, mpi_size, error )
c     
c      Get the individual process ID.
c     
          call MPI_Comm_rank ( MPI_COMM_WORLD, mpi_rank, error )


          seed = (/42,77,1,7,31,27,99,215/)
          call random_seed(put=(seed*(mpi_size + mpi_rank)))

          do i=1,10
              call random_number(r)
              print *, "rank=", mpi_rank, r
          enddo

          call MPI_Finalize( error )
      end
