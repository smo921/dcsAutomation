-- Busted testing example for DCS mission scripting

-- Load mocks
dofile("tests/mocks/dcs_mocks.lua")

-- Load the modules to test
dofile("scripts/unit_management.lua")

describe("ConfigStandards with Busted", function()
    describe("createSector", function()
        it("creates a sector with default values", function()
            local config = ConfigStandards.createSector({
                groupName = "Test_Group"
            })

            assert.are.equal("Test_Group", config.groupName)
            assert.are.equal("GROUND", config.category)
            assert.are.equal("IMMEDIATE", config.triggerType)
            assert.are.equal("Russia", config.country)
        end)

        it("overrides default values", function()
            local config = ConfigStandards.createSector({
                groupName = "Test_Group",
                category = "AIRPLANE",
                country = "USA"
            })

            assert.are.equal("Test_Group", config.groupName)
            assert.are.equal("AIRPLANE", config.category)
            assert.are.equal("USA", config.country)
        end)
    end)

    describe("createDrone", function()
        it("creates a drone with default values", function()
            local drone = ConfigStandards.createDrone({
                groupName = "Test_Drone"
            })

            assert.are.equal("Test_Drone", drone.groupName)
            assert.are.equal("MQ-9 Reaper", drone.unitType)
            assert.are.equal("USA", drone.country)
            assert.are.equal(4572, drone.altitude)
        end)
    end)

    describe("deepCopy", function()
        it("creates a deep copy of a table", function()
            local original = {
                a = 1,
                b = {
                    c = 2,
                    d = {
                        e = 3
                    }
                }
            }

            local copy = ConfigStandards.deepCopy(original)

            -- Should be equal
            assert.are.equal(original.a, copy.a)
            assert.are.equal(original.b.c, copy.b.c)
            assert.are.equal(original.b.d.e, copy.b.d.e)

            -- But not the same reference
            assert.are_not.equal(original, copy)
            assert.are_not.equal(original.b, copy.b)
            assert.are_not.equal(original.b.d, copy.b.d)
        end)
    end)
end)

describe("SpatialSolver with Busted", function()
    describe("getBullseye", function()
        it("returns bullseye coordinates", function()
            local blue_bullseye = SpatialSolver.getBullseye("blue")
            local red_bullseye = SpatialSolver.getBullseye("red")

            assert.is_not_nil(blue_bullseye)
            assert.is_not_nil(red_bullseye)
            assert.are.equal(0, blue_bullseye.x)
            assert.are.equal(0, blue_bullseye.y)
            assert.are.equal(5000, red_bullseye.x)
            assert.are.equal(5000, red_bullseye.y)
        end)
    end)

    describe("getVector", function()
        it("calculates vector coordinates", function()
            local origin = {x = 0, y = 0}
            local x, y = SpatialSolver.getVector(origin, 0, 1) -- 0 degrees, 1 NM

            -- Should be pointing north (positive y)
            assert.is_true(y > 0)
            assert.is_true(math.abs(x) < 1) -- Should be close to 0
        end)
    end)
end)