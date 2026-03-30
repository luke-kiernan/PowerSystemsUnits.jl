using Test
using PowerSystemsUnits
using Unitful

# Mock components for testing
struct MockGen
    active_power::Float64
    base_power::Float64
end

struct MockLine
    r::Float64
    x::Float64
end

PowerSystemsUnits.get_device_base_power(g::MockGen) = g.base_power
PowerSystemsUnits.get_system_base_power(::MockGen) = 100.0
PowerSystemsUnits.get_base_voltage(::MockGen) = 230.0

PowerSystemsUnits.get_device_base_power(::MockLine) = 100.0
PowerSystemsUnits.get_system_base_power(::MockLine) = 100.0
PowerSystemsUnits.get_base_voltage(::MockLine) = 230.0

@testset "PowerSystemsUnits" begin
    @testset "RelativeQuantity construction and arithmetic" begin
        a = 0.6DU
        b = 0.4DU
        @test a isa RelativeQuantity{Float64, DeviceBaseUnit}
        @test ustrip(a) == 0.6
        @test ustrip(a + b) ≈ 1.0
        @test ustrip(a - b) ≈ 0.2
        @test ustrip(-a) ≈ -0.6
        @test ustrip(2.0 * a) ≈ 1.2
        @test ustrip(a * 2.0) ≈ 1.2
        @test ustrip(a / 2.0) ≈ 0.3
    end

    @testset "RelativeQuantity comparisons" begin
        @test 0.6DU == 0.6DU
        @test 0.6DU < 0.7DU
        @test 0.7DU > 0.6DU
        @test 0.6DU <= 0.6DU
        @test isapprox(0.6DU, 0.60000001DU; atol = 1e-6)
        @test isless(0.6DU, 0.7DU)
    end

    @testset "DU and SU cannot be mixed" begin
        @test_throws Exception 0.6DU + 0.4SU
        @test_throws Exception 0.6DU == 0.4SU
    end

    @testset "zero and one" begin
        @test zero(RelativeQuantity{Float64, DeviceBaseUnit}) == 0.0DU
        @test one(RelativeQuantity{Float64, DeviceBaseUnit}) == 1.0DU
    end

    @testset "Display" begin
        @test sprint(show, 0.6DU) == "0.6 DU"
        @test sprint(show, 0.3SU) == "0.3 SU"
        @test sprint(show, DU) == "DU"
        @test sprint(show, SU) == "SU"
    end

    @testset "Unit categories" begin
        @test natural_unit(POWER) == u"MW"
        @test natural_unit(IMPEDANCE) == u"Ω"
        @test natural_unit(ADMITTANCE) == u"S"
        @test natural_unit(VOLTAGE) == u"kV"
        @test natural_unit(CURRENT) == u"kA"
    end

    @testset "base_value and system_base_value" begin
        gen = MockGen(0.6, 50.0)  # 50 MVA device, 100 MVA system

        @test base_value(gen, POWER) == 50.0
        @test system_base_value(gen, POWER) == 100.0

        # Impedance: V² / S
        @test base_value(gen, IMPEDANCE) ≈ 230.0^2 / 50.0
        @test system_base_value(gen, IMPEDANCE) ≈ 230.0^2 / 100.0

        # Admittance: S / V²
        @test base_value(gen, ADMITTANCE) ≈ 50.0 / 230.0^2
        @test system_base_value(gen, ADMITTANCE) ≈ 100.0 / 230.0^2

        @test base_value(gen, VOLTAGE) == 230.0
        @test system_base_value(gen, VOLTAGE) == 230.0
    end

    @testset "convert_units: DU → other" begin
        gen = MockGen(0.6, 50.0)

        # DU → MW
        result = convert_units(gen, 0.6, POWER, DU, MW)
        @test result isa Unitful.Quantity
        @test Unitful.ustrip(result) ≈ 30.0

        # DU → SU
        result = convert_units(gen, 0.6, POWER, DU, SU)
        @test result isa RelativeQuantity{Float64, SystemBaseUnit}
        @test ustrip(result) ≈ 0.3

        # DU → DU (identity)
        result = convert_units(gen, 0.6, POWER, DU, DU)
        @test ustrip(result) ≈ 0.6

        # DU → Float64
        result = convert_units(gen, 0.6, POWER, DU, Float64)
        @test result isa Float64
        @test result ≈ 0.3
    end

    @testset "convert_units: SU → other" begin
        gen = MockGen(0.6, 50.0)

        # SU → MW
        result = convert_units(gen, 0.3, POWER, SU, MW)
        @test Unitful.ustrip(result) ≈ 30.0

        # SU → DU
        result = convert_units(gen, 0.3, POWER, SU, DU)
        @test ustrip(result) ≈ 0.6

        # SU → SU (identity)
        result = convert_units(gen, 0.3, POWER, SU, SU)
        @test ustrip(result) ≈ 0.3
    end

    @testset "convert_units: natural → per-unit" begin
        gen = MockGen(0.6, 50.0)

        # MW → DU
        result = convert_units(gen, 30.0MW, POWER, MW, DU)
        @test ustrip(result) ≈ 0.6

        # MW → SU
        result = convert_units(gen, 30.0MW, POWER, MW, SU)
        @test ustrip(result) ≈ 0.3
    end

    @testset "convert_units: impedance" begin
        line = MockLine(0.01, 0.1)
        z_base = 230.0^2 / 100.0

        # DU → Ω
        result = convert_units(line, 0.01, IMPEDANCE, DU, OHMS)
        @test Unitful.ustrip(result) ≈ 0.01 * z_base

        # DU → Float64 (device base == system base, so ratio = 1.0)
        result = convert_units(line, 0.01, IMPEDANCE, DU, Float64)
        @test result ≈ 0.01
    end

    @testset "convert_units: nothing passthrough" begin
        gen = MockGen(0.6, 50.0)
        @test convert_units(gen, nothing, POWER, DU, MW) === nothing
    end

    @testset "Round-trip consistency" begin
        gen = MockGen(0.6, 50.0)
        original = 0.6

        # DU → MW → DU
        mw = convert_units(gen, original, POWER, DU, MW)
        back = convert_units(gen, mw, POWER, MW, DU)
        @test ustrip(back) ≈ original

        # DU → SU → DU
        su = convert_units(gen, original, POWER, DU, SU)
        back = convert_units(gen, ustrip(su), POWER, SU, DU)
        @test ustrip(back) ≈ original
    end

    @testset "ComplexF64 support" begin
        line = MockLine(0.01, 0.1)
        z = 0.01 + 0.1im

        result = convert_units(line, z, IMPEDANCE, DU, Float64)
        @test result isa ComplexF64
        @test result ≈ z  # ratio is 1.0 since device == system base
    end

    @testset "NU (natural units)" begin
        gen = MockGen(0.6, 50.0)

        # NU returns the value with the category's natural unit attached
        result = convert_units(gen, 0.6, POWER, DU, NU)
        @test result isa Unitful.Quantity
        @test Unitful.ustrip(result) ≈ 30.0

        result = convert_units(gen, 0.01, IMPEDANCE, DU, NU)
        @test Unitful.dimension(Unitful.unit(result)) == Unitful.dimension(u"Ω")

        # NU as source
        result = convert_units(gen, 30.0MW, POWER, NU, DU)
        @test ustrip(result) ≈ 0.6
    end

    @testset "Custom Unitful units" begin
        @test 1.0Mvar == 1.0u"MW"  # same dimension
        @test 1.0MVA == 1.0u"MW"
        @test sprint(show, 1.0Mvar) == "1.0 Mvar"
        @test sprint(show, 1.0MVA) == "1.0 MVA"
    end
end
