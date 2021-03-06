! Copyright (c) 2018 Matthew J. Smith and Overkit contributors
! License: MIT (http://opensource.org/licenses/MIT)

module ovkGlobal

#ifdef f2003
  use, intrinsic iso_fortran_env, only : INPUT_UNIT, OUTPUT_UNIT, ERROR_UNIT
#endif

  implicit none

  private

  ! Public API
  public :: ovk_rk
  public :: ovk_lk
  public :: ovk_bk
  public :: ovkCaseID
  public :: OVK_DEBUG
  public :: OVK_FALSE, OVK_TRUE
  public :: OVK_NONE, OVK_ANY, OVK_NOT_ALL, OVK_ALL
  public :: OVK_NO_ERROR, OVK_IO_ERROR
  public :: OVK_MIRROR
  public :: OVK_PERIODIC_STORAGE_UNIQUE, OVK_PERIODIC_STORAGE_DUPLICATED
  public :: OVK_LITTLE_ENDIAN, OVK_BIG_ENDIAN
  public :: OVK_P3D_STANDARD, OVK_P3D_EXTENDED
  public :: OVK_ALL_GRIDS
  public :: OVK_CONNECTION_NONE, OVK_CONNECTION_NEAREST, OVK_CONNECTION_LINEAR, OVK_CONNECTION_CUBIC
  public :: OVK_OCCLUDES_NONE, OVK_OCCLUDES_ALL, OVK_OCCLUDES_COARSE

  ! Internal API
  public :: rk
  public :: lk
  public :: bk
  public :: INPUT_UNIT, OUTPUT_UNIT, ERROR_UNIT
  public :: MAX_DIMS
  public :: PATH_LENGTH
  public :: STRING_LENGTH
  public :: IntToString
  public :: LargeIntToString
  public :: TupleToString
  public :: CoordsToString
  public :: t_noconstruct
  public :: t_existence_flag
  public :: SetExists
  public :: CheckExists

  integer, parameter :: ovk_rk = selected_real_kind(15, 307)
  integer, parameter :: ovk_lk = selected_int_kind(18)
  integer, parameter :: ovk_bk = selected_int_kind(1)

  character(len=256) :: ovkCaseID = ""

#ifdef OVERKIT_DEBUG
  logical, parameter :: OVK_DEBUG = .true.
#else
  logical, parameter :: OVK_DEBUG = .false.
#endif

  integer, parameter :: OVK_FALSE = 0
  integer, parameter :: OVK_TRUE = 1

  integer, parameter :: OVK_NONE = 0
  integer, parameter :: OVK_ANY = 1
  integer, parameter :: OVK_NOT_ALL = 2
  integer, parameter :: OVK_ALL = 3

  integer, parameter :: OVK_NO_ERROR = 0
  integer, parameter :: OVK_IO_ERROR = 1

  integer, parameter :: OVK_MIRROR = 2

  integer, parameter :: OVK_PERIODIC_STORAGE_UNIQUE = 1
  integer, parameter :: OVK_PERIODIC_STORAGE_DUPLICATED = 2

  integer, parameter :: OVK_LITTLE_ENDIAN = 1
  integer, parameter :: OVK_BIG_ENDIAN = 2

  integer, parameter :: OVK_P3D_STANDARD = 1
  integer, parameter :: OVK_P3D_EXTENDED = 2

  integer, parameter :: OVK_ALL_GRIDS = -1

  integer, parameter :: OVK_CONNECTION_NONE = 0
  integer, parameter :: OVK_CONNECTION_NEAREST = 1
  integer, parameter :: OVK_CONNECTION_LINEAR = 2
  integer, parameter :: OVK_CONNECTION_CUBIC = 3

  integer, parameter :: OVK_OCCLUDES_NONE = 0
  integer, parameter :: OVK_OCCLUDES_ALL = 1
  integer, parameter :: OVK_OCCLUDES_COARSE = 2

#ifndef f2003
  integer, parameter :: INPUT_UNIT = 5
  integer, parameter :: OUTPUT_UNIT = 6
  integer, parameter :: ERROR_UNIT = 0
#endif

  integer, parameter :: rk = ovk_rk
  integer, parameter :: lk = ovk_lk
  integer, parameter :: bk = ovk_bk

  integer, parameter :: MAX_DIMS = 3

  integer, parameter :: PATH_LENGTH = 256

  ! Length of strings used in ToString function
  integer, parameter :: STRING_LENGTH = 256

  ! Empty type which, when used as a member of another type, prevents Fortran built-in
  ! constructor from being called; useful for catching instances of constructor calls with
  ! the trailing underscore omitted (e.g., ovk_<type>(...) vs. ovk_<type>_(...)), which
  ! otherwise don't always produce compiler errors
  type t_noconstruct
  end type t_noconstruct

  ! Reliable check for whether an object exists
  ! Works even when object hasn't been initialized, due to special properties of allocatable
  type t_existence_flag
    integer, dimension(:), allocatable :: value
  end type t_existence_flag

contains

  pure elemental function IntToString(N) result(NString)

    integer, intent(in) :: N
    character(len=STRING_LENGTH) :: NString
  
    NString = LargeIntToString(int(N,kind=lk))

  end function IntToString

  pure elemental function LargeIntToString(N) result(NString)

    integer(lk), intent(in) :: N
    character(len=STRING_LENGTH) :: NString

    integer :: i, j
    integer :: NumDigits
    integer :: NumBeforeComma
    character(len=STRING_LENGTH) :: UnformattedNString

    write (UnformattedNString, '(i0)') N

    if (N >= 0) then
      NumDigits = len_trim(UnformattedNString)
      NumBeforeComma = modulo(NumDigits-1, 3) + 1
    else
      NumDigits = len_trim(UnformattedNString)-1
      NumBeforeComma = modulo(NumDigits-1, 3) + 2
    end if

    NString(:NumBeforeComma) = UnformattedNString(:NumBeforeComma)

    j = NumBeforeComma + 1
    do i = NumBeforeComma + 1, len_trim(UnformattedNString)
      if (modulo(i-NumBeforeComma-1, 3) == 0) then
        NString(j:j) = ','
        j = j + 1
      end if
      NString(j:j) = UnformattedNString(i:i)
      j = j + 1
    end do

    NString(j:) = ''

  end function LargeIntToString

  function TupleToString(Tuple) result(TupleString)

    integer, dimension(:), intent(in) :: Tuple
    character(len=STRING_LENGTH) :: TupleString

    integer :: i
    character(len=STRING_LENGTH), dimension(size(Tuple)) :: SeparatorStrings
    character(len=STRING_LENGTH) :: EntryString

    SeparatorStrings(:size(Tuple)-1) = ","
    SeparatorStrings(size(Tuple):) = ""

    TupleString = "("
    do i = 1, size(Tuple)
      write (EntryString, '(i0)') Tuple(i)
      TupleString = trim(TupleString) // trim(EntryString) // trim(SeparatorStrings(i))
    end do
    TupleString = trim(TupleString) // ")"

  end function TupleToString

  pure function CoordsToString(Coords) result(CoordsString)

    real(rk), dimension(:), intent(in) :: Coords
    character(len=STRING_LENGTH) :: CoordsString

    integer :: i
    character(len=STRING_LENGTH), dimension(size(Coords)) :: SeparatorStrings
    character(len=STRING_LENGTH) :: EntryString

    SeparatorStrings(:size(Coords)-1) = ","
    SeparatorStrings(size(Coords):) = ""

    CoordsString = "("
    do i = 1, size(Coords)
      write (EntryString, '(f10.4)') Coords(i)
      CoordsString = trim(CoordsString) // trim(EntryString) // trim(SeparatorStrings(i))
    end do
    CoordsString = trim(CoordsString) // ")"

  end function CoordsToString

  pure subroutine SetExists(ExistenceFlag, Value)

    type(t_existence_flag), intent(inout) :: ExistenceFlag
    logical, intent(in) :: Value

    logical :: OldValue

    OldValue = allocated(ExistenceFlag%value)

    if (Value .neqv. OldValue) then
      if (.not. OldValue) then
        allocate(ExistenceFlag%value(1))
      else
        deallocate(ExistenceFlag%value)
      end if
    end if

  end subroutine SetExists

  pure function CheckExists(ExistenceFlag) result(Value)

    type(t_existence_flag), intent(in) :: ExistenceFlag
    logical :: Value

    Value = allocated(ExistenceFlag%value)

  end function CheckExists

end module ovkGlobal
