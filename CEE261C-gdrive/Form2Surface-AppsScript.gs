function onFormSubmit(e) {
  var parentFolderName = "CEE261C-2025";
  var parentFolders = DriveApp.getFoldersByName(parentFolderName);

  if (!parentFolders.hasNext()) return;
  var classFolder = parentFolders.next();

  // Locate or create the SUBS folder
  var subsFolder = getOrCreateFolder(classFolder, "SUBS");

  var responses = e.namedValues;
  var userEmail = responses['Email Address'][0].split('@')[0];
  var windDirection = responses['Wind direction (in degrees)'][0];
  var domainDimensions = responses['Domain dimensions in [X0 X1 Y0 Y1 Z0 Z1] at full scale [m]'][0]; // Domain dimensions input

  // Parse domain dimensions into individual values
  var domainValues = domainDimensions.split(' ').map(function(val) {
    return parseFloat(val.trim());
  });
  var X0 = domainValues[0], X1 = domainValues[1];
  var Y0 = domainValues[2], Y1 = domainValues[3];
  var Z0 = domainValues[4], Z1 = domainValues[5];

  // Log domain values for debugging
  Logger.log("Parsed Domain Values: ");
  Logger.log("  X0: " + X0 + ", X1: " + X1);
  Logger.log("  Y0: " + Y0 + ", Y1: " + Y1);
  Logger.log("  Z0: " + Z0 + ", Z1: " + Z1);

  // Retrieve uploaded file information
  var uploadedFileUrl = responses['Upload your .STL file (full scale [m])'][0]; 
  var fileId = extractFileId(uploadedFileUrl);
  var uploadedFileName = "";

  if (fileId) {
    try {
      var uploadedFile = DriveApp.getFileById(fileId);
      uploadedFileName = uploadedFile.getName();
    } catch (error) {
      Logger.log("Error retrieving file: " + error.message);
      uploadedFileName = "Error retrieving file name";
    }
  } else {
    uploadedFileName = "No file uploaded or invalid file URL";
  }

  // Create the student's folder inside SUBS
  var userFolder = getOrCreateFolder(subsFolder, userEmail);
  var assignmentFolder = getOrCreateFolder(userFolder, 'HW5');
  var subNo = getNextSubmissionNumber(assignmentFolder);
  var subFolderName = 'submission_surfer-' + ('0' + subNo).slice(-2);
  var subFolder = assignmentFolder.createFolder(subFolderName);

  // Write responses.txt file with better formatting for domain dimensions
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
      "Uploaded file: " + (uploadedFileName || "None");
  subFolder.createFile(fileName, fileContent);

  // Copy and rename uploaded file to the submission folder
  if (fileId && uploadedFileName !== "Error retrieving file name") {
    var uploadedFile = DriveApp.getFileById(fileId);
    uploadedFile.makeCopy("building.stl", subFolder); // Rename file to 'building.stl'
  }
}

function getOrCreateFolder(parentFolder, folderName) {
  var folders = parentFolder.getFoldersByName(folderName);
  if (folders.hasNext()) {
    return folders.next();
  } else {
    var newFolder = parentFolder.createFolder(folderName);
    Logger.log("Created folder: " + folderName);
    return newFolder;
  }
}

function getNextSubmissionNumber(folder) {
  var folders = folder.getFolders();
  var highestNumber = 0;

  while (folders.hasNext()) {
    var match = folders.next().getName().match(/submission_surfer-(\d+)/);
    if (match) {
      var currentNumber = parseInt(match[1], 10);
      if (currentNumber > highestNumber) highestNumber = currentNumber;
    }
  }
  return highestNumber + 1;
}

function extractFileId(url) {
  var match = url.match(/[-\w]{25,}/);
  return match ? match[0] : null;
}
