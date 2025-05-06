import fs from 'fs';
import path from 'path';
import { exec } from 'child_process';
import { fileURLToPath } from 'url';

// Get the directory name in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Source icon path
const sourceIcon = path.join(__dirname, 'generated-icon.png');

// Verify source icon exists
if (!fs.existsSync(sourceIcon)) {
  console.error('Source icon not found:', sourceIcon);
  process.exit(1);
}

// Icon sizes for PWA
const sizes = [72, 96, 128, 144, 152, 192, 384, 512];

// Make sure the icons directory exists
const iconsDir = path.join(__dirname, 'public', 'icons');
if (!fs.existsSync(iconsDir)) {
  fs.mkdirSync(iconsDir, { recursive: true });
}

// Function to resize icon
function resizeIcon(size) {
  const outputPath = path.join(iconsDir, `icon-${size}x${size}.png`);
  const command = `convert ${sourceIcon} -resize ${size}x${size} ${outputPath}`;
  
  return new Promise((resolve, reject) => {
    exec(command, (error) => {
      if (error) {
        console.error(`Error creating ${size}x${size} icon:`, error);
        reject(error);
      } else {
        console.log(`Created ${size}x${size} icon at ${outputPath}`);
        resolve();
      }
    });
  });
}

// Create icons for all sizes
async function createIcons() {
  try {
    for (const size of sizes) {
      await resizeIcon(size);
    }
    console.log('All PWA icons created successfully!');
  } catch (error) {
    console.error('Error creating PWA icons:', error);
    process.exit(1);
  }
}

createIcons();
