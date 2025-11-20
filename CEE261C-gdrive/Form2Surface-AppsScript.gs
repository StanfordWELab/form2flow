/**
 * Trigger: Install an "On form submit" trigger for this function.
 */
function onFormSubmit(e) {
  var parentFolderName = "CEE261C-2025F";
  var parentFolders = DriveApp.getFoldersByName(parentFolderName);
  if (!parentFolders.hasNext()) return;
  var classFolder = parentFolders.next();

  // Locate or create the SUBS folder
  var subsFolder = getOrCreateFolder(classFolder, "SUBS");

  var responses = e.namedValues;

  // --- Read basic fields from the form ---
  var userEmail = (responses['Email Address'] && responses['Email Address'][0]) 
      ? responses['Email Address'][0].split('@')[0] 
      : 'unknown';
  var windDirection = (responses['Wind direction (in degrees)'] && responses['Wind direction (in degrees)'][0]) 
      ? responses['Wind direction (in degrees)'][0] 
      : 'N/A';
  var domainDimensions = (responses['Domain dimensions in [X0 X1 Y0 Y1 Z0 Z1] at full scale [m]'] && responses['Domain dimensions in [X0 X1 Y0 Y1 Z0 Z1] at full scale [m]'][0]) 
      ? responses['Domain dimensions in [X0 X1 Y0 Y1 Z0 Z1] at full scale [m]'][0] 
      : '';

  // --- Create the student's submission folder ---
  var userFolder = getOrCreateFolder(subsFolder, userEmail);
  var assignmentFolder = getOrCreateFolder(userFolder, 'HW5');
  var subNo = getNextSubmissionNumber(assignmentFolder);
  var subFolderName = 'submission_surfer-' + ('0' + subNo).slice(-2);
  var subFolder = assignmentFolder.createFolder(subFolderName);

  // Parse domain dimensions safely
  var X0 = '', X1 = '', Y0 = '', Y1 = '', Z0 = '', Z1 = '';
  if (domainDimensions) {
    var domainValues = domainDimensions.split(' ').map(function (val) { return parseFloat(val.trim()); });
    X0 = domainValues[0]; X1 = domainValues[1];
    Y0 = domainValues[2]; Y1 = domainValues[3];
    Z0 = domainValues[4]; Z1 = domainValues[5];
  }

  Logger.log("Parsed Domain Values:");
  Logger.log("  X0: " + X0 + ", X1: " + X1);
  Logger.log("  Y0: " + Y0 + ", Y1: " + Y1);
  Logger.log("  Z0: " + Z0 + ", Z1: " + Z1);

  // --- File-upload question labels (MUST match your Form exactly) ---
  var stlFieldLabel  = 'Upload your .STL file (full scale [m])';
  var jsonFieldLabel = 'Upload your plane_definitions.json file';

  // --- Copy files into the submission folder ---
  // STL → building.stl
  var stlResult = copyFormFileToFolder(responses, stlFieldLabel, subFolder, 'building.stl');
  // JSON → plane_definitions.json
  var jsonResult = copyFormFileToFolder(responses, jsonFieldLabel, subFolder, 'plane_definitions.json');

  // --- Write summary file ---
  var fileName = 'responses_surfer.txt';
  var fileContent =
    "Wind direction: " + windDirection + "\n" +
    "Domain dimensions:\n" +
    "  X0: " + X0 + "\n" +
    "  X1: " + X1 + "\n" +
    "  Y0: " + Y0 + "\n" +
    "  Y1: " + Y1 + "\n" +
    "  Z0: " + Z0 + "\n" +
    "  Z1: " + Z1 + "\n" +
    "Uploaded STL: " + (stlResult.originalName || stlResult.message || "N/A") + "\n" +
    "Uploaded JSON: " + (jsonResult.originalName || jsonResult.message || "N/A") + "\n";
  subFolder.createFile(fileName, fileContent);
}

/**
 * Get or create a subfolder.
 */
function getOrCreateFolder(parentFolder, folderName) {
  var folders = parentFolder.getFoldersByName(folderName);
  if (folders.hasNext()) return folders.next();
  var newFolder = parentFolder.createFolder(folderName);
  Logger.log("Created folder: " + folderName);
  return newFolder;
}

/**
 * Find the next submission number based on existing folder names.
 * Looks for folders like: submission_surfer-01, submission_surfer-02, ...
 */
function getNextSubmissionNumber(folder) {
  var folders = folder.getFolders();
  var highestNumber = 0;
  while (folders.hasNext()) {
    var name = folders.next().getName();
    var match = name.match(/submission_surfer-(\d+)/);
    if (match) {
      var currentNumber = parseInt(match[1], 10);
      if (currentNumber > highestNumber) highestNumber = currentNumber;
    }
  }
  return highestNumber + 1;
}

/**
 * Extracts a Drive file ID from a URL string.
 * Works for typical Google Forms/Drive share links.
 */
function extractFileId(url) {
  var match = url && url.match(/[-\w]{25,}/);
  return match ? match[0] : null;
}

/**
 * Copies a file uploaded via a Google Form file-upload question into destFolder,
 * renaming it to destName. Returns {success, originalName, message}.
 *
 * - If the form question allows multiple files, the first URL is used.
 * - If permissions prevent access to the file, the error is logged and returned.
 */
function copyFormFileToFolder(responses, fieldLabel, destFolder, destName) {
  var result = { success: false, originalName: null, message: "" };

  if (!responses[fieldLabel] || !responses[fieldLabel][0]) {
    result.message = "No file uploaded for field: " + fieldLabel;
    Logger.log(result.message);
    return result;
  }

  // Handle potential multiple URLs (comma-separated)
  var candidate = responses[fieldLabel][0];
  var firstUrl = candidate.split(/,\s*/)[0];
  var fileId = extractFileId(firstUrl);

  if (!fileId) {
    result.message = "Invalid file URL for field: " + fieldLabel;
    Logger.log(result.message + " | URL: " + firstUrl);
    return result;
  }

  try {
    var srcFile = DriveApp.getFileById(fileId);
    result.originalName = srcFile.getName();

    // Copy with a consistent name
    srcFile.makeCopy(destName, destFolder);

    result.success = true;
    result.message = "Copied as " + destName;
    Logger.log("Copied '" + result.originalName + "' to '" + destName + "' in " + destFolder.getName());
  } catch (err) {
    result.message = "Error copying file for field '" + fieldLabel + "': " + err.message;
    Logger.log(result.message);
  }

  return result;
}
