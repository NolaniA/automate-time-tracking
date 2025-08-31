#!/bin/bash

# 🤖 Automated Timesheet (version.Yearly)

# ❌ ❌ 📁 สำหรับรายละเอียดและวิธีใช้งานไม่เกิน 7 บรรทัด จุดไหนสำคัญจะมี // comment บอก
# 1. แก้ 📋 /config.csv เป็นชื่อ และ project ตัวเอง
# 2. แก้วันที่และงานที่ทำเรียงจากเดือน 1 -12 ใน 📋 /yearly_tasks.json มีตัวอย่างอยู่ในไฟล์นั้น
# 3. user macOs - open bash terminal 
# 4. run คำสั่ง "chmod +x yearly_track.sh" > Enter
# 5. run คำสั่ง "./yearly_track.sh" > Enter 
# 6. ❌ สำคัญ !! 💥💥 ตรง STEP:4 :: แก้ format Date ให้ถูกต้อง เชคกับ input วันที่บน airTable ในเครื่อง ว่าเป็นแบบ yyyy/mm/dd หรือ MM/dd/yyyy (บางเครื่อง format ไม่เหมือนกัน) ไม่งั้น date input error
# 7. ถ้าอยาก custom code เอง // step ย่อยที่อยู่ใน 💥 legacy:: อย่าไปแก้ จุดอื่นแก้ได้หมด ไม่งั้นโค้ดระเบิด 💣 💥

# ปล. **** auto track แบบรายปีจะไม่ใช้ข้อมูล config.csv ที่เป็น START_DAY,END_DAY,START_MONTH,START_YEAR จะเอาออกก็ได้



# STEP:0 💥 legacy:: ห้ามแก้
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📁 Script directory: $SCRIPT_DIR"
cd "$SCRIPT_DIR" || { echo "❌ ไม่สามารถเข้า directory ได้"; exit 1; }

# 0.1. ตรวจสอบ Node.js และ npm
if ! command -v node &> /dev/null
then
    echo "❌ Node.js ไม่ได้ติดตั้ง กรุณาติดตั้ง Node.js ก่อน"
    exit 1
fi

echo "✅ พบ Node.js เวอร์ชัน: $(node -v)"
echo "✅ พบ npm เวอร์ชัน: $(npm -v)"

# 0.2. สร้าง package.json ถ้ายังไม่มี
if [ ! -f package.json ]; then
  echo "📦 กำลังสร้าง package.json..."
  npm init -y > /dev/null
  echo "✅ สร้าง package.json เรียบร้อย"
fi

# 0.3. สร้างโฟลเดอร์ node_modules ถ้ายังไม่มี
if [ ! -d "node_modules" ]; then
  echo "📁 ไม่พบ node_modules สร้างใหม่"
else
  echo "📁 พบ node_modules แล้ว"
fi

# 0.4. ตรวจสอบและติดตั้ง playwright
echo "🔍 กำลังตรวจสอบ playwright..."
npm list playwright &> /dev/null
if [ $? -ne 0 ]; then
  echo "🔄 กำลังติดตั้ง playwright..."
  echo "⏳ อาจใช้เวลาสักครู่ กรุณารอ..."
  npm install playwright --no-optional --verbose
  if npm list playwright &> /dev/null; then
    echo "✅ ติดตั้ง playwright เรียบร้อย"
  else
    echo "❌ ติดตั้ง playwright ไม่สำเร็จ"
    npx install playwright
    if npm list playwright &> /dev/null; then
      echo "✅ ติดตั้ง playwright สำเร็จ (ครั้งที่ 2)"
    else
      echo "❌ ไม่สามารถติดตั้ง playwright ได้"
      echo "📋 กรุณาลองติดตั้งด้วยตนเอง: npx install playwright"
      exit 1
    fi
  fi
else
  echo "✅ พบแพ็กเกจ playwright แล้ว"
fi

# 0.5. ตรวจสอบและติดตั้ง date-fns
echo "🔍 กำลังตรวจสอบ date-fns..."
npm list date-fns &> /dev/null
if [ $? -ne 0 ]; then
  echo "🔄 กำลังติดตั้ง date-fns..."
  npm install date-fns
  if npm list date-fns &> /dev/null; then
    echo "✅ ติดตั้ง date-fns เรียบร้อย"
  else
    echo "❌ ติดตั้ง date-fns ไม่สำเร็จ"
    exit 1
  fi
else
  echo "✅ พบแพ็กเกจ date-fns แล้ว"
fi

# STEP:1 แก้ไขแหล่งข้อมูล file ตรงนี้ได้
CONFIG_FILE="config.csv"
YEARLY_TASKS_FILE="yearly_tasks.json"
SCRIPT_FILE="airtable_submit.mjs"

# 1.1 check config.csv file
if [[ ! -f $CONFIG_FILE ]]; then
  echo "❌ Not found: $CONFIG_FILE"
  exit 1
fi

echo "📄 Found config: $CONFIG_FILE"


# 1.2 import data from json file strat month 1 -> 12
if [[ ! -f $YEARLY_TASKS_FILE ]]; then
  echo "📄 Creating sample $YEARLY_TASKS_FILE..."
  cat << 'EOF' > "$YEARLY_TASKS_FILE"
{
  "2025-07-29": [
    {
      "task": "Fix authentication bug in login module",
      "type": "work",
      "hours": "2"
    }
  ]
}
EOF
  echo "✅ Created sample $YEARLY_TASKS_FILE"
fi

# STEP:2 💥 legacy:: ห้ามแก้ - สร้างไฟล์ automate เขียน airtable_submit.mjs
cat << 'EOF' > "$SCRIPT_FILE"
import { readFileSync } from 'fs';
import { chromium } from 'playwright';
import { format, isWeekend } from 'date-fns';

// ตรงนี้แก้ได้ :: การเรียกข้อมูลโดยอ่าน config.csv
const configText = readFileSync('./config.csv', 'utf-8');
const configLines = configText.trim().split('\n').slice(1);
const config = {};
for (const line of configLines) {
  const [key, ...rest] = line.split(',');
  const value = rest.join(',').trim();
  if (key && value) config[key.trim()] = value;
}


// ตรงนี้แก้ได้ :: การเรียกข้อมูลโดยอ่าน yearly_tasks.json
let yearlyTasks = {};
try {
  yearlyTasks = JSON.parse(readFileSync('./yearly_tasks.json', 'utf-8'));
} catch (err) {
  console.error("❌ Failed to load yearly_tasks.json:", err.message);
  process.exit(1);
}


// STEP:3 💥 legacy:: ห้ามแก้ - การ selecte field - data input
const EMPLOYEE_NAME = config.EMPLOYEE_NAME;
const PROJECT_NAME = config.PROJECT_NAME;
const COMPANY = config.COMPANY || "FutureSkill";

const TASK_TYPE_MAPPING = {
  'work': 'Create / Do / Work',
  'audit': 'Audit Work',
  'plan': 'Plan / Think', 
  'coordinate': 'Co-Ordinate',
  'meeting': 'Internal Meeting',
  'idle': 'Idle',
  'leave': 'Leave',
  'other': 'Other'
};



function createTaskFromMonthlyWork(monthlyTask) {
  return {
    taskType: TASK_TYPE_MAPPING[monthlyTask.type] || 'Create / Do / Work',
    taskItem: monthlyTask.task,
    taskNote: monthlyTask.task,
    hours: monthlyTask.hours
  };
}

(async () => {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext({ viewport: { width: 1250, height: 600 } });
  const page = await context.newPage();
  await page.goto("https://airtable.com/app6PjJAAPwiRw71N/pagWjJnFT2ZQn7eka/form", { waitUntil: 'domcontentloaded' });

  console.log("Please login manually and press ENTER to continue...");
  await new Promise(resolve => process.stdin.once('data', resolve));

  const workdays = [];
  const startDate = new Date(Object.keys(yearlyTasks)[0]); // ใช้วันแรกใน JSON เป็น reference

  for (const dateStr of Object.keys(yearlyTasks)) {
    const currentDate = new Date(dateStr);
    if (isNaN(currentDate)) continue;
    if (isWeekend(currentDate)) continue;

    const logDataTrack = yearlyTasks[dateStr];

    const allTasks = [];
    
    logDataTrack.forEach((monthlyTask, idx) => {
      allTasks.push({ activity: `DAILY_WORK_${idx + 1}`, source: 'daily', ...createTaskFromMonthlyWork(monthlyTask) });
    });

// STEP:4 💥💥 สำคัญ !! เชค date input ของ airTable ในเครื่อง ว่าเป็นแบบ yyyy/mm/dd หรือ MM/dd/yyyy แล้วแก้บรรทัดล่างให้ตรง บางคนใช้ต่างกันรีเชคดีๆ
    workdays.push({
      date: format(currentDate, 'MM/dd/yyyy'),
      dayName: format(currentDate, 'EEEE'),
      tasks: allTasks
    });
  }

  
// STEP:5 💥 legacy:: ห้ามแก้ - ส่วนของการกรอกฟอร์มยังเหมือนเดิม
  for (const dayData of workdays) {
    console.log(`\n🗓️ Starting ${dayData.date} (${dayData.dayName}) - ${dayData.tasks.length} tasks`);
    
    for (let taskIndex = 0; taskIndex < dayData.tasks.length; taskIndex++) {
      const task = dayData.tasks[taskIndex];
      console.log(`\n🔄 Processing Task ${taskIndex + 1}/${dayData.tasks.length}: ${task.activity} - ${task.taskItem} (${task.hours}h)...`);
      
      // รอให้หน้าโหลดเสร็จ
      await page.waitForLoadState('domcontentloaded');
      await page.waitForSelector('button[type="submit"]', { timeout: 120000 });
      
      // คลิก submit เพื่อเริ่มกรอกฟอร์ม
      await page.click('button[type="submit"]');
      console.log('✅ Clicked submit button');

      // รอให้ปุ่ม unlink ปรากฏแล้วคลิก
      try {
        const unlinkBtn = page.locator('div[data-testid="unlink-foreign-key"]');
        await unlinkBtn.waitFor({ state: 'visible', timeout: 10000 });
        await unlinkBtn.hover();
        await page.waitForTimeout(500);
        await unlinkBtn.click();
        await unlinkBtn.waitFor({ state: 'detached', timeout: 60000 });
        console.log('✅ Cleared auto-fill');
      } catch (error) {
        console.log('ℹ️ No unlink button found, continuing...');
      }

      // รอให้ error message ปรากฏ
      await page.waitForSelector('text=This field is required.', { timeout: 120000 });
      console.log('✅ Form validation appeared');

      // กรอกวันที่
      console.log(`📅 Filling date: ${dayData.date}`);
      const dateInput = page.locator('input.date');
      await dateInput.click();
      await page.keyboard.press('Control+a');
      await page.keyboard.type(`${dayData.date}`, { delay: 150 });
      await dateInput.waitFor({ state: 'visible' });
      await page.keyboard.press('Tab');
      await page.waitForTimeout(1000);
      
      // ตรวจสอบว่าวันที่ถูกกรอกแล้ว
      const dateValue = await dateInput.inputValue();
      console.log(`Date filled: ${dateValue}`);

      // กรอกพนักงาน
      console.log(`👤 Filling employee: ${EMPLOYEE_NAME}`);
      await page.click('button[aria-label="Add employee to Employee field"]');
      await page.waitForSelector('div[data-testid="search-input"] input', { state: 'visible' });
      const employeeInput = page.locator('div[data-testid="search-input"] input');
      await employeeInput.clear();
      await employeeInput.fill(EMPLOYEE_NAME);
      await page.keyboard.press('Enter');
      await page.waitForSelector(`text=${EMPLOYEE_NAME}`, { timeout: 120000 });
      console.log('✅ Employee selected');

      // กรอกโปรเจค
      console.log(`📁 Filling project: ${PROJECT_NAME}`);
      await page.click('button[aria-label="Add project to Project ID field"]');
      await page.waitForSelector('div[data-testid="search-input"] input', { state: 'visible' });
      const projectInput = page.locator('div[data-testid="search-input"] input');
      await projectInput.clear();
      await projectInput.fill(PROJECT_NAME);
      await page.keyboard.press('Enter');
      await page.waitForSelector(`text=${PROJECT_NAME}`, { timeout: 120000 });
      console.log('✅ Project selected');

      // กรอกบริษัท
      console.log(`🏢 Filling company: ${COMPANY}`);
      await page.click('div[data-tutorial-selector-id="pageCellLabelPairCompany"] button');
      await page.waitForTimeout(500);
      await page.keyboard.type(COMPANY, { delay: 100 });
      await page.keyboard.press('Enter');
      await page.waitForSelector(`div >> text="${COMPANY}"`, { timeout: 120000 });
      console.log('✅ Company selected');

      // กรอกประเภทงาน
      console.log(`📋 Filling task type: ${task.taskType}`);
      await page.click('div[data-testid="autocomplete-button"]');
      await page.waitForTimeout(500);
      await page.keyboard.type(task.taskType, { delay: 50 });
      await page.keyboard.press('Enter');
      await page.waitForSelector(`div[title="${task.taskType}"]`, { timeout: 120000 });
      console.log('✅ Task type selected');

      // กรอกรายการงาน
      console.log(`📝 Filling task item: ${task.taskItem}`);
      await page.click('div[data-tutorial-selector-id="pageCellLabelPairTaskItem"] div[data-testid="cell-editor"]');
      await page.waitForTimeout(500);
      await page.keyboard.type(task.taskItem, { delay: 50 });
      await page.keyboard.press('Enter');
      await page.waitForSelector(`text=${task.taskItem}`, { timeout: 120000 });
      console.log('✅ Task item filled');

      // กรอกหมายเหตุ
      console.log(`📋 Filling task note: ${task.taskNote}`);
      await page.click('div[data-tutorial-selector-id="pageCellLabelPairTaskNote"] div[data-testid="cell-editor"]');
      await page.waitForTimeout(500);
      await page.keyboard.type(task.taskNote, { delay: 50 });
      await page.keyboard.press('Enter');
      await page.waitForSelector(`textarea >> text=${task.taskNote}`, { timeout: 120000 });
      console.log('✅ Task note filled');

      // กรอกจำนวนชั่วโมง
      console.log(`⏰ Filling hours: ${task.hours}`);
      const hoursInput = page.locator('div[data-tutorial-selector-id="pageCellLabelPairSpentHours"] input');
      await hoursInput.click();
      await hoursInput.clear();
      await hoursInput.fill(task.hours);
      await page.keyboard.press('Tab');
      console.log('✅ Hours filled');

      // 💥 legacy:: ถ้าจะเทสยิงแต่ยังไม่ส่งฟอร์ม // comment บรรทัดด้านล่างทั้งหมดจนถึง completed
      console.log('📤 Submitting form...');
      await page.click('button[type="submit"]');

      // รอให้ส่งเสร็จ
      await page.waitForSelector('div.refreshButton', { timeout: 200000 });
      console.log('✅ Form submitted successfully');

      // คลิกปุ่ม refresh
      await page.click('div.refreshButton');
      await page.waitForTimeout(2000);
      console.log('🔄 Page refreshed');
      
      console.log(`✨ Task ${taskIndex + 1}/${dayData.tasks.length} completed: ${task.activity}`);
    }
    
    console.log(`🎯 Day ${dayData.date} completed! All ${dayData.tasks.length} tasks submitted.`);
  }

  console.log("\n🎉 Done! All entries completed successfully.");
  await browser.close();
})();
EOF

echo "✅ สร้างไฟล์ $SCRIPT_FILE เรียบร้อย"

# 10. รันสคริปต์
echo "🚀 กำลังรันสคริปต์..."
node "$SCRIPT_FILE"

echo "✅ เสร็จสิ้น!"