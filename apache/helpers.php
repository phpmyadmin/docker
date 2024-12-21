<?php

class SslFileGenerationException extends Exception {}

define('OUTPUT_DIR', '/etc/phpmyadmin/ssl');

/**
 * Helper function to decode and save multiple SSL files from base64.
 *
 * @param string $base64_string The base64 encoded string containing multiple SSL files separated by commas.
 *                               If no commas are present, the entire string is treated as a single file.
 * @param string $prefix The prefix to use for the generated SSL file names.
 * @param string $extension The file extension to use for the generated SSL files.
 * @return string A comma-separated list of paths to the generated SSL files.
 */
function decodeAndSaveSslFiles(string $base64_string, string $prefix, string $extension): array {
    // Ensure the output directory exists
    if (!is_dir(OUTPUT_DIR)) {
        mkdir(OUTPUT_DIR, 0755, true);
    }

    // Split the base64 string into an array of files
    $files = strpos($base64_string, ',') !== false ? explode(',', $base64_string) : [$base64_string];
    $counter = 1;
    $ssl_files = [];

    // Process each file
    foreach ($files as $file) {
        $output_file = OUTPUT_DIR . "/pma-ssl-$prefix-$counter.$extension";
        
        // Write the decoded file to the output directory
        if (file_put_contents($output_file, base64_decode($file)) === false) {
            echo 'Failed to write to ' . $output_file;
            exit(1);
        }
        
        // Add the output file path to the list
        $ssl_files[] = $output_file;
        $counter++;
    }

    // Return a comma-separated list of the generated file paths
    return implode(',', $ssl_files);
}
