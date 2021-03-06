# @author Scott Dobbins
# @version 0.9.8.3
# @date 2017-08-24 22:30


### Context -----------------------------------------------------------------

context("Cleaning raw data")

debug_message("unit testing cleaned bomb data")


### Cardinality -------------------------------------------------------------

test_that("no data column is completely empty or identical across all rows", {
  WW1_bombs %>% map_int(~expect_gt(cardinality(.), 1L))
  WW2_bombs %>% map_int(~expect_gt(cardinality(.), 1L))
  Korea_bombs1 %>% select(-Takeoff_Latitude, -Takeoff_Longitude) %>% map_int(~expect_gt(cardinality(.), 1L))
  Korea_bombs2 %>% select(-Unit_Country, -Reference_Source) %>% map_int(~expect_gt(cardinality(.), 1L))
  Vietnam_bombs %>% select(-Weapon_Class2) %>% map_int(~expect_gt(cardinality(.), 1L))
})


### Text Length -------------------------------------------------------------

test_that("no text column is excessively long", {
  walk(bomb_data, 
      function(dt) dt %>% keep(is.character) %>% 
        map_int(~expect_lt(max(nchar(levels(as.factor(.)))), max_string_length)))
  
  walk(bomb_data, 
       function(dt) dt %>% keep(is.factor) %>% 
         map_int(~expect_lt(max(nchar(levels(.))), max_string_length)))
})


### Value Range -------------------------------------------------------------

test_that("value ranges for mission dates are reasonable", {
  expect_true(WW1_bombs[, all(range(Mission_Date, na.rm = TRUE) %between% c(WW1_first_mission, WW1_last_mission))])
  expect_true(WW2_bombs[, all(range(Mission_Date, na.rm = TRUE) %between% c(WW2_first_mission, WW2_last_mission))])
  expect_true(Korea_bombs1[, all(range(Mission_Date, na.rm = TRUE) %between% c(Korea_first_mission, Korea_last_mission))])
  expect_true(Korea_bombs2[, all(range(Mission_Date, na.rm = TRUE) %between% c(Korea_first_mission, Korea_last_mission))])
  expect_true(Vietnam_bombs[, all(range(Mission_Date, na.rm = TRUE) %between% c(Vietnam_first_mission, Vietnam_last_mission))])
})

test_that("didn't somehow delete USA from unit countries (as proxy for basic unit country handling)", {
  expect_true("USA" %c% levels(WW1_bombs$Unit_Country))
  expect_true("USA" %c% levels(WW2_bombs$Unit_Country))
  
  expect_true("USA" %c% levels(Vietnam_bombs$Unit_Country))
})

test_that("value ranges for altitudes are reasonable", {
  expect_equal(WW1_bombs[Bomb_Altitude_Feet == 0L, .N], 0L)
  expect_lte(WW1_bombs[, max(Bomb_Altitude_Feet, na.rm = TRUE)], WW1_altitude_max_feet)
  
  expect_equal(WW2_bombs[Bomb_Altitude_Feet == 0L, .N], 0L)
  expect_lte(WW2_bombs[, max(Bomb_Altitude_Feet, na.rm = TRUE)], WW2_altitude_max_feet)
  
  expect_equal(Korea_bombs2[Bomb_Altitude_Feet_Low == 0L | Bomb_Altitude_Feet_High == 0L, .N], 0L)
  expect_lte(Korea_bombs2[, max(Bomb_Altitude_Feet_Low, Bomb_Altitude_Feet_High, na.rm = TRUE)], Korea_altitude_max_feet)
  
  expect_equal(Vietnam_bombs[Bomb_Altitude_Feet == 0L, .N], 0L)
  expect_lte(Vietnam_bombs[, max(Bomb_Altitude_Feet, na.rm = TRUE)], Vietnam_altitude_max_feet)
})

test_that("no zero values for essential integer columns", {
  expect_equal(WW1_bombs[Aircraft_Attacking_Num == 0L, .N], 0L)
  expect_equal(WW1_bombs[Weapon_Expended_Num == 0L, .N], 0L)
  expect_equal(WW1_bombs[Weapon_Weight_Pounds == 0L, .N], 0L)
  
  expect_equal(WW2_bombs[Aircraft_Attacking_Num == 0L, .N], 0L)
  expect_equal(WW2_bombs[Weapon_Expl_Num == 0L & Weapon_Incd_Num == 0L & Weapon_Frag_Num == 0L, .N], 0L)
  expect_equal(WW2_bombs[Weapon_Expl_Pounds == 0L & Weapon_Incd_Pounds == 0L & Weapon_Frag_Pounds == 0L, .N], 0L)
  
  expect_equal(Korea_bombs1[Aircraft_Attacking_Num == 0L, .N], 0L)
  # expect_equal(Korea_bombs1[Weapon_Expended_Num == 0L, .N], 0L)
  expect_equal(Korea_bombs1[Weapon_Weight_Pounds == 0L, .N], 0L)
  
  expect_equal(Korea_bombs2[Aircraft_Attacking_Num == 0L, .N], 0L)
  expect_equal(Korea_bombs2[Weapon_Expended_Num == 0L, .N], 0L)
  expect_equal(Korea_bombs2[Weapon_Weight_Pounds == 0L, .N], 0L)
  
  expect_equal(Vietnam_bombs[Aircraft_Attacking_Num == 0L, .N], 0L)
  expect_equal(Vietnam_bombs[Weapon_Expended_Num == 0L & Weapon_Jettisoned_Num == 0L & Weapon_Returned_Num == 0L, .N], 0L)
  expect_equal(Vietnam_bombs[Weapon_Weight_Pounds == 0L, .N], 0L)
})


### Completeness ------------------------------------------------------------

test_that("no string values are NA", {
  walk(bomb_data, 
       function(dt) dt %>% keep(is.character) %>% 
         map_lgl(~expect_false(anyNA(.))))
  
  walk(bomb_data, 
       function(dt) dt %>% keep(is.factor) %>% 
         map_lgl(~expect_false(anyNA(.))))
})

test_that("there are no NA levels in factors", {
  walk(bomb_data, 
       function(dt) dt %>% keep(is.factor) %>% 
         map_lgl(~expect_false(anyNA(levels(.)))))
})

test_that("no missing levels exist", {
  walk(bomb_data, 
       function(dt) dt %>% keep(is.factor) %>% 
         map_lgl(~expect_false(any(tabulate_factor(.) == 0L))))
})


### Formatting --------------------------------------------------------------

test_that("all times formatted properly", {
  expect_equal(WW1_bombs[Takeoff_Time != "" & Takeoff_Time %!like% "^[0-9]{2}:[0-9]{2}$", .N], 0L)
  
  expect_equal(WW2_bombs[Bomb_Time != "" & Bomb_Time %!like% "^[0-9]{1,2}:[0-9]{2}$", .N], 0L)
  
  levels(Vietnam_bombs[["Bomb_Time_Start"]]) %>% (expect_false(any(. != "" & . %!like% "^[0-9]{1,2}:[0-9]{2}$")))
  expect_equal(Vietnam_bombs[Bomb_Time_Finish != "" & Bomb_Time_Finish %!like% "^[0-9]{1,2}:[0-9]{2}$", .N], 0L)
})

test_that("no double whitespace in factor columns", {
  walk(bomb_data, 
       function(dt) dt %>% keep(is.factor) %>% 
         map_lgl(~expect_false(any(grepl(levels(.), pattern = "\\s{2,}")))))
})

test_that("no quotation marks in text columns", {
  walk(bomb_data, 
       function(dt) dt %>% keep(is.character) %>% 
         map_lgl(~expect_false(any(grepl(., pattern = '\\"', fixed = TRUE)))))
  
  walk(bomb_data, 
       function(dt) dt %>% keep(is.factor) %>% 
         map_lgl(~expect_false(any(grepl(levels(.), pattern = '\\"', fixed = TRUE)))))
})

test_that("no backslashes in text columns", {
  walk(bomb_data, 
       function(dt) dt %>% keep(is.character) %>% 
         map_lgl(~expect_false(any(grepl(., pattern = "\\\\", fixed = TRUE)))))
  
  walk(bomb_data, 
       function(dt) dt %>% keep(is.factor) %>% 
         map_lgl(~expect_false(any(grepl(levels(.), pattern = "\\\\", fixed = TRUE)))))
})


### Names -------------------------------------------------------------------

test_that("none of the levels have names", {
  walk(bomb_data, 
       function(dt) dt %>% keep(is.factor) %>% 
         walk(~expect_null(names(levels(.)))))
})

test_that("none of the data has names", {
  walk(bomb_data, 
       function(dt) dt %>% 
         walk(~expect_null(names(.))))
})
