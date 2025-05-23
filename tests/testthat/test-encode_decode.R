test_that("json_encode_dir encodes a directory to JSON", {
  dir <- tempfile()
  dir.create(dir)
  file.create(file.path(dir, "test.txt"))
  writeLines("Hello, World!", file.path(dir, "test.txt"))

  json_data <- json_encode_dir(dir)
  expect_true(grepl("test.txt", json_data))
  expect_true(grepl("Hello, World!", json_data))
})

test_that("json_decode_dir decodes JSON to a directory", {
  dir <- tempfile()
  dir.create(dir)
  file.create(file.path(dir, "test.txt"))
  writeLines("Hello, World!", file.path(dir, "test.txt"))

  json_data <- json_encode_dir(dir)

  new_dir <- tempfile()
  json_decode_dir(json_data, new_dir)

  expect_true(file.exists(file.path(new_dir, "test.txt")))
  expect_equal(readLines(file.path(new_dir, "test.txt")), "Hello, World!")
})

test_that("json_encode_dir respects the type parameter", {
  dir <- tempfile()
  dir.create(dir)
  
  # Create text and binary files
  text_file <- file.path(dir, "test.txt")
  binary_file <- file.path(dir, "test.bin")
  file.create(text_file)
  file.create(binary_file)
  writeLines("This is a text file.", text_file)
  writeBin(as.raw(1:10), binary_file)

  # Test for text files only
  json_data_text <- json_encode_dir(dir, type = "text")
  expect_true(grepl("test.txt", json_data_text))
  expect_false(grepl("test.bin", json_data_text))

  # Test for binary files only
  json_data_binary <- json_encode_dir(dir, type = "binary")
  expect_false(grepl("test.txt", json_data_binary))
  expect_true(grepl("test.bin", json_data_binary))

  # Test for both text and binary files
  json_data_both <- json_encode_dir(dir, type = c("text", "binary"))
  expect_true(grepl("test.txt", json_data_both))
  expect_true(grepl("test.bin", json_data_both))
})

test_that("json_encode_dir includes metadata when specified", {
  dir <- tempfile()
  dir.create(dir)

  # Create a test file
  test_file <- file.path(dir, "test.txt")
  file.create(test_file)
  writeLines("This is a test file.", test_file)

  # Get file info for comparison
  file_info <- fs::file_info(test_file)

  # Test with file_size metadata
  json_data_size <- json_encode_dir(dir, metadata = "file_size")
  expect_true(grepl(paste0("\"file_size\":", file_info$size), json_data_size))

  # Test with creation_time metadata
  json_data_creation <- json_encode_dir(dir, metadata = "creation_time")
  expect_true(grepl("creation_time", json_data_creation))

  # Test with last_modified_time metadata
  json_data_modified <- json_encode_dir(dir, metadata = "last_modified_time")
  expect_true(grepl("last_modified_time", json_data_modified))

  # Test with multiple metadata fields
  json_data_all <- json_encode_dir(dir, metadata = c("file_size", "creation_time", "last_modified_time"))
  expect_true(grepl(paste0("\"file_size\":", file_info$size), json_data_all))
  expect_true(grepl("creation_time", json_data_all))
  expect_true(grepl("last_modified_time", json_data_all))
})

test_that("json_encode_dir respects the ignore parameter", {
  dir <- tempfile()
  dir.create(dir)

  # Create test files
  file1 <- file.path(dir, "include.txt")
  file2 <- file.path(dir, "exclude.txt")
  file.create(file1)
  file.create(file2)
  writeLines("This file should be included.", file1)
  writeLines("This file should be excluded.", file2)

  # Test with ignore parameter
  json_data <- json_encode_dir(dir, ignore = "exclude.txt")
  expect_true(grepl("include.txt", json_data))
  expect_false(grepl("exclude.txt", json_data))

  # Test without ignore parameter
  json_data_no_ignore <- json_encode_dir(dir)
  expect_true(grepl("include.txt", json_data_no_ignore))
  expect_true(grepl("exclude.txt", json_data_no_ignore))
})

test_that("validate_dir_json accepts valid JSON", {
  valid_json <- jsonlite::toJSON(list(
    list(name = "file1.txt", content = "hello world"),
    list(name = "file2.bin", content = "aGVsbG8=", type = "binary")
  ), auto_unbox = TRUE)
  expect_true(validate_dir_json(valid_json))
})

test_that("validate_dir_json rejects invalid JSON", {
  # Not a JSON string
  expect_error(validate_dir_json("not json"), "Invalid JSON")

  # Not a list
  invalid_json <- jsonlite::toJSON(list(), auto_unbox = TRUE)
  expect_error(validate_dir_json(invalid_json), "non-empty list")

  # Missing 'name'
  missing_name <- jsonlite::toJSON(list(list(content = "abc")), auto_unbox = TRUE)
  expect_error(validate_dir_json(missing_name), "must have 'name' and 'content'")

  # Invalid 'type'
  invalid_type <- jsonlite::toJSON(list(list(name = "f", content = "abc", type = "foo")), auto_unbox = TRUE)
  expect_error(validate_dir_json(invalid_type), "Invalid 'type' field")
})

test_that("validate_dir_json allows optional type", {
  json <- jsonlite::toJSON(list(list(name = "f", content = "abc")), auto_unbox = TRUE)
  expect_true(validate_dir_json(json))
})
