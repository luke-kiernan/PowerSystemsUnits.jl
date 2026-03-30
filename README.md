# PowerSystemsUnits.jl

Standalone unit conversion library for power systems, built on [Unitful.jl](https://github.com/PainterQubits/Unitful.jl).

Provides per-unit types (`DU`, `SU`), unit categories (`POWER`, `IMPEDANCE`, etc.), and generic conversion between device base, system base, and natural units (MW, Ω, S, kV).

## Usage

```julia
using PowerSystemsUnits

# Downstream packages implement the interface for their component types:
PowerSystemsUnits.get_device_base_power(g::MyGen) = g.base_power
PowerSystemsUnits.get_system_base_power(g::MyGen) = 100.0
PowerSystemsUnits.get_base_voltage(g::MyGen) = 230.0

# Convert between unit systems
convert_units(gen, 0.6, POWER, DU, MW)       # 30.0 MW
convert_units(gen, 0.6, POWER, DU, SU)       # 0.3 SU
convert_units(gen, 0.6, POWER, DU, NU)       # 30.0 MW (natural units)
convert_units(gen, 0.6, POWER, DU, Float64)  # 0.3 (raw SU, no wrapper)

# Round-trip
convert_units(gen, 30.0MW, POWER, NU, DU)    # 0.6 DU

# Per-unit arithmetic with type safety
0.6DU + 0.4DU   # 1.0 DU
0.6DU + 0.4SU   # error — can't mix unit systems
```

## Target unit types

- `DU` — device base per-unit. Returns a `RelativeQuantity`.
- `SU` — system base per-unit. Returns a `RelativeQuantity`.
- `NU` — natural units. A dispatch token (not a number wrapper) that returns the value with
  the appropriate Unitful unit for the category (MW for power, Ω for impedance, etc.).
- `Float64` — raw numeric value in system base, no unit wrapper. For internal computation.
- Any Unitful unit (e.g., `MW`, `OHMS`) — converts and attaches that unit.

## Unit categories

| Category | Natural unit | `base_value` (1.0 DU =) |
|---|---|---|
| `POWER` | MW | `device_base_power` |
| `IMPEDANCE` | Ω | `V² / device_base_power` |
| `ADMITTANCE` | S | `device_base_power / V²` |
| `VOLTAGE` | kV | `base_voltage` |
| `CURRENT` | kA | `device_base_power / base_voltage` |
