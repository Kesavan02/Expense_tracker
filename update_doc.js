const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'Expense_Tracker_Specification.doc');
const outPath = path.join(__dirname, 'Expense_Tracker_Specification_7_days.doc');

let content = fs.readFileSync(filePath, 'utf8');

// Replace the 10-day timeline with a 7-day timeline
content = content.replace('1st day: Project Setup & Foundation', 'Day 1: Project Setup, Foundation, Backend API & Auth');
content = content.replace('2nd day: Backend API & Authentication Logic', 'Day 2: Frontend Auth, Design System, & Routing');
content = content.replace('3rd day: Frontend Auth & Design System', 'Day 3: Offline Storage Setup & Basic UI Setup');
content = content.replace('4th day: Role-based Routing & Profile Settings', 'Day 4: User Home Screen, Admin Dashboard & Basic Features');
content = content.replace('5th day: Offline Storage Setup (Hive)', 'Day 5: Transaction Management (Core)');
content = content.replace('6th day: User Home Screen & Admin Dashboard', 'Day 6: Advanced Budgeting & Visual Trackers');
content = content.replace('7th day: Transaction Management (Core)', 'Day 7: Quality Assurance & Final Polish');

// Find and eliminate Days 8, 9, 10
// We'll isolate the substring from "8th day: Implementing Advanced Budgeting" to the end
const day8StartStr = '8th day: Implementing Advanced Budgeting';
let day8StartIndex = content.indexOf(day8StartStr);

if (day8StartIndex !== -1) {
    // Find the nearest <h3 before it
    const beforeH3 = content.lastIndexOf('<h3', day8StartIndex);
    if (beforeH3 !== -1) {
        // Find the end of the document before </body>
        const endStr = '</div><!--EndFragment--></body></html>';
        const endIndex = content.indexOf(endStr, beforeH3);
        
        if(endIndex !== -1) {
            content = content.substring(0, beforeH3) + endStr;
        }
    }
}

// Standardize fonts to Arial
content = content.replace(/font-family:SimSun/g, "font-family:Arial, sans-serif");
content = content.replace(/font-family:'Times New Roman'/g, "font-family:Arial, sans-serif");
content = content.replace(/font-family:Calibri/g, "font-family:Arial, sans-serif");
content = content.replace(/font-family:Symbol/g, "font-family:Arial, sans-serif");

fs.writeFileSync(outPath, content, 'utf8');
console.log('Successfully written to ' + outPath);
