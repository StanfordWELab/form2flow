function onFormSubmit(e) {
  var parentFolderName = "CEE261C-2025F";
  var parentFolders = DriveApp.getFoldersByName(parentFolderName);

  if (!parentFolders.hasNext()) return;
  var classFolder = parentFolders.next();

  var responses = e.namedValues;
  var userEmail = responses['Email Address'][0].split('@')[0];

  // Locate or create the SUBS folder
  var subsFolder = getOrCreateFolder(classFolder, "SUBS-dev");
  var userFolder = getOrCreateFolder(subsFolder, userEmail);
  var assignmentFolder = getOrCreateFolder(userFolder, 'HW5');
  var subNo = getNextSubmissionNumber(assignmentFolder);
  var subFolderName = 'submission-' + ('0' + subNo).slice(-2);
  var subFolder = assignmentFolder.createFolder(subFolderName);

  
  // Retrieve the responses from the form
  var simulationType = responses['What type of simulation would you like to run?'][0];
  var surfer_number = responses['What surfer submission number would you like to use. (e.g., 01)'][0];
  var buildingHeight = responses['What is the target building height in meters?'][0];
  var gridResolution = responses['Select the desired grid resolution. These meshes vary solely in terms of grid size around the target building location, while the placement, size, and number of transition layers in the refinement boxes away from the building surface remain consistent. LV0 correspond to the background grid size, and LV3 is the grid size on the target building.'][0];
  var terrainCategory = responses['The inflow boundary condition applies a logarithmic mean velocity profile at the domain inlet, with U = 15 m/s at a height of 20 m.\n\nTo generate turbulence, a divergence-free digital filter creates a synthetic turbulent field. The inflow atmospheric boundary layer statistics follow the profiles outlined in the class slides.\n\nThe simulation runs for 30,000 timesteps with Δt = 0.05 s, totaling 1,500 seconds of simulated time. Statistics are collected after a 300-second burn-in period\n\nBelow you can choose the terrain category.'][0];
  var zPlaneHeights = responses['Post-processing z-plane. Height in meters [z1, z2, z3, etc.]'][0];
  var yPlaneDistances = responses['Post-processing y-plane. Distance from the center in meters [y1, y2, y3, etc.]'][0];

  var fileFieldLabel = 'Upload optional simulation files';

  // --- Copy files into the submission folder ---
  var stlResult = copyFormFileToFolder(responses, fileFieldLabel, subFolder);

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
      "Surfer Number: " + surfer_number;
  subFolder.createFile(fileName, fileContent);
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

/**
 * Extracts a Drive file ID from a URL string.
 * Works for typical Google Forms/Drive share links.
 */
function extractFileId(url) {
  var match = url && url.match(/[-\w]{25,}/);
  return match ? match[0] : null;
}

/**
 * Copies files uploaded via a Google Form file-upload question into destFolder,
 *
 * - If permissions prevent access to the files, the error is logged and returned.
 */
function copyFormFileToFolder(responses, fieldLabel, destFolder) {
  var result = { success: false, originalName: null, message: "" };

  if (!responses[fieldLabel] || responses[fieldLabel].length === 0) {
    result.message = "No file uploaded for field: " + fieldLabel;
    Logger.log(result.message);
    return result;
  }
  
  // Split the comma-separated URLs from the single string
  var urlString = responses[fieldLabel][0];
  var urls = urlString.split(/,\s*/);
  Logger.log("Found " + urls.length + " file URLs");
  
  for (var i = 0; i < urls.length; i++) {
    var fileId = extractFileId(urls[i]);

    if (!fileId) {
      Logger.log("Invalid file URL at index " + i + ": " + urls[i]);
      continue;
    }

    try {
      var srcFile = DriveApp.getFileById(fileId);
      var originalName = srcFile.getName();
      var parts = originalName.split(' - ');
      var base = parts[0].trim();
      var extMatch = originalName.match(/(\.[^.]*)$/);
      var ext = extMatch ? extMatch[1] : '';
      if (ext && base.endsWith(ext)) {
        base = base.slice(0, -ext.length);
      }
      var destName = base + ext;

      // Copy with a consistent name
      srcFile.makeCopy(destName, destFolder);

      result.success = true;
      result.message = "Copied as " + destName;
      Logger.log("Copied '" + originalName + "' to '" + destName + "' in " + destFolder.getName());
    } catch (err) {
      Logger.log("Error copying file at index " + i + ": " + err.message);
    }
  }
  return result;
}