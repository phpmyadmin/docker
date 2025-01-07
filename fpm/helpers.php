<?php

declare(strict_types=1);

/**
 * Helper function to decode and save multiple SSL files from base64.
 *
 * @param string $base64FilesContents The base64 encoded string containing multiple files separated by commas.
 *                                    If no commas are present, the entire string is treated as a single file.
 * @param string $prefix              The prefix to use for the generated file names.
 * @param string $extension           The file extension to use for the generated files.
 * @param string $storageFolder       The folder where to store the generated files.
 *
 * @return string A comma-separated list of paths to the generated files.
 */
function decodeBase64AndSaveFiles(string $base64FilesContents, string $prefix, string $extension, string $storageFolder): string
{
    // Ensure the output directory exists
    if (! is_dir($storageFolder)) {
        mkdir($storageFolder, 0755, true);
    }

    // Split the base64 string into an array of files
    $base64FilesContents = explode(',', trim($base64FilesContents));
    $counter = 1;
    $outputFiles = [];

    // Process each file
    foreach ($base64FilesContents as $base64FileContent) {
        $outputFile = $storageFolder . '/' . $prefix . '-' . $counter . '.' . $extension;

        $fileContent = base64_decode($base64FileContent, true);
        if ($fileContent === false) {
            echo 'Failed to decode: ' . $base64FileContent;
            exit(1);
        }

        // Write the decoded file to the output directory
        if (file_put_contents($outputFile, $fileContent) === false) {
            echo 'Failed to write to ' . $outputFile;
            exit(1);
        }

        // Add the output file path to the list
        $outputFiles[] = $outputFile;
        $counter++;
    }

    // Return a comma-separated list of the generated file paths
    return implode(',', $outputFiles);
}
