module PowerSystemsUnits

using Unitful: @u_str, @unit, Quantity, Units, uconvert
import Unitful: ustrip
import Unitful

include("types.jl")
include("conversions.jl")

function __init__()
    Unitful.register(PowerSystemsUnits)
end

# Types
export AbstractRelativeUnit, DeviceBaseUnit, SystemBaseUnit, NaturalUnit
export RelativeQuantity, DU, SU, NU

# Unitful re-exports
export MW, Mvar, MVA, kV, OHMS, SIEMENS
export ustrip

# Unit categories
export UnitCategory, PowerCategory, ImpedanceCategory, AdmittanceCategory,
    VoltageCategory, CurrentCategory
export POWER, IMPEDANCE, ADMITTANCE, VOLTAGE, CURRENT

# Conversion interface (implemented by downstream packages)
export get_device_base_power, get_system_base_power, get_base_voltage

# Conversion functions
export natural_unit, base_value, system_base_value
export convert_units, DEFAULT_UNITS

end # module PowerSystemsUnits
