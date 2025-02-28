function onFormSubmit(e) {
  var parentFolderName = "CEE261C-2025";
  var parentFolders = DriveApp.getFoldersByName(parentFolderName);

  if (!parentFolders.hasNext()) return;
  var classFolder = parentFolders.next();

  // Locate or create the SUBS folder
  var subsFolder = getOrCreateFolder(classFolder, "SUBS");

  var responses = e.namedValues;
  var userEmail = responses['Email Address'][0].split('@')[0];
  
  // Retrieve the responses from the form
  var simulationType = responses['What type of simulation would you like to run?'][0];
  var uploadedFileUrl = responses['Upload one of the following sbin files:\n- For empty domain: surfer_emptyDomain.sbin\n- For isolated building: surfer_isolatedBuilding.sbin\n- For urban environment: surfer_urbanEnv.sbin'][0];
  var buildingHeight = responses['What is the target building height in meters?'][0];
  var gridResolution = responses['Select the desired grid resolution. These meshes vary solely in terms of grid size around the target building location, while the placement, size, and number of transition layers in the refinement boxes away from the building surface remain consistent. LV0 correspond to the background grid size, and LV3 is the grid size on the target building.'][0];
  var terrainCategory = responses['The inflow boundary condition applies a logarithmic mean velocity profile at the domain inlet, with U = 15 m/s at a height of 20 m.\n\nTo generate turbulence, a divergence-free digital filter creates a synthetic turbulent field. The inflow atmospheric boundary layer statistics follow the profiles outlined in the class slides.\n\nThe simulation runs for 30,000 timesteps with Δt = 0.05 s, totaling 1,500 seconds of simulated time. Statistics are collected after a 300-second burn-in period\n\nBelow you can choose the terrain category.'][0];
  var zPlaneHeights = responses['Post-processing z-plane. Height in meters [z1, z2, z3, etc.]'][0];
  var yPlaneDistances = responses['Post-processing y-plane. Distance from the center in meters [y1, y2, y3, etc.]'][0];

  // Retrieve uploaded file information
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
  var assignmentFolder = getOrCreateFolder(userFolder, 'Final');
  var subNo = getNextSubmissionNumber(assignmentFolder);
  var subFolderName = 'submission-' + ('0' + subNo).slice(-2);
  var subFolder = assignmentFolder.createFolder(subFolderName);

  // Write responses.txt file
  var fileName = 'responses.txt';
  var fileContent = 
      "SUID: " + userEmail + "\n" +
      "Simulation Type: " + simulationType + "\n" +
      "Target Building Height (m): " + buildingHeight + "\n" +
      "Grid Resolution: " + gridResolution + "\n" +
      "Terrain Category: " + terrainCategory + "\n" +
      "Post-processing z-plane heights: " + zPlaneHeights + "\n" +
      "Post-processing y-plane distances: " + yPlaneDistances + "\n" +
      "Uploaded file: " + (uploadedFileName || "None");
  subFolder.createFile(fileName, fileContent);

  // Copy and rename uploaded file to the submission folder
  if (fileId && uploadedFileName !== "Error retrieving file name") {
    var uploadedFile = DriveApp.getFileById(fileId);
    uploadedFile.makeCopy("surfer_output.sbin", subFolder);
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