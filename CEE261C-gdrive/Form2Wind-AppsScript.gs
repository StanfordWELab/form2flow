function onFormSubmit(e) {
  var parentFolderName = "CEE261C-2025";
  var parentFolders = DriveApp.getFoldersByName(parentFolderName);

  if (!parentFolders.hasNext()) return;
  var classFolder = parentFolders.next();

  // Locate or create the SUBS-dev folder
  var subsFolder = getOrCreateFolder(classFolder, "SUBS");

  var responses = e.namedValues;
  var userEmail = responses['Email Address'][0].split('@')[0];
  
  // Retrieve the responses from the form
  var res1 = responses['Choose mesh refinement'][0]; // Mesh refinement
  var res2 = responses['Terrain inflow category'][0]; // Terrain inflow category
  var zPlaneHeights = responses['Post-processing z-plane. Height in meters [z1, z2, z3, etc.]'][0]; // z-plane heights
  var yPlaneDistances = responses['Post-processing y-plane. Distance from the center in meters [y1, y2, y3, etc.]'][0]; // y-plane distances

  // Retrieve uploaded file information
  var uploadedFileUrl = responses['Upload your surfer_output.sbin file'][0]; 
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

  // Create the student's folder inside SUBS-dev
  var userFolder = getOrCreateFolder(subsFolder, userEmail);
  var assignmentFolder = getOrCreateFolder(userFolder, 'HW4');
  var subNo = getNextSubmissionNumber(assignmentFolder);
  var subFolderName = 'submission-' + ('0' + subNo).slice(-2);
  var subFolder = assignmentFolder.createFolder(subFolderName);

  // Write responses.txt file
  var fileName = 'responses.txt';
  var fileContent = 
      "SUID: " + userEmail + "\n" +
      "Mesh refinement: " + res1 + "\n" +
      "Terrain inflow category: " + res2 + "\n" +
      "Post-processing z-plane heights: " + zPlaneHeights + "\n" +
      "Post-processing y-plane distances: " + yPlaneDistances + "\n" + // Add y-plane distances
      "Uploaded file: " + (uploadedFileName || "None");
  subFolder.createFile(fileName, fileContent);

  // Copy and rename uploaded file to the submission folder
  if (fileId && uploadedFileName !== "Error retrieving file name") {
    var uploadedFile = DriveApp.getFileById(fileId);
    uploadedFile.makeCopy("surfer_output.sbin", subFolder); // Rename the file to 'surfer_output.sbin'
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
    var match = folders.next().getName().match(/submission-(\d+)/);
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
