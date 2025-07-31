#!/bin/bash

# ********❌  Note (อ่านก่อนเหยดแหม่) ❌ ******** #

#  ✅  ต้องมี file ชื่อ config.csv
#  ✅  ตรวจเช็ค  START_DAY , END_DAY ,START_MONTH ,START_YEAR, EMPLOYEE_NAME, PROJECT_NAME และ COMPANY 
# แก้ไข value ใน config.csv ให้ตรงกับของตัวเอง ✅

# 🚀  วิธี run (cd ไปที่ path ของไฟล์นี้ก่อน --> cd /your-drive/automate-time-tracking/ )
# 1.  เปิด terminal แล้ว run คำสั่ง chmod +x timesheet.sh กด Enter
# 2.  run คำสั่ง ./timesheet.sh 
# 2 . อ่าน terminal แล้วทำตาม

# -------------------- ตัวอย่าง config.csv ------------------------- #

#    key,value
#    START_DAY,29
#    END_DAY,31
#    START_MONTH,7
#    START_YEAR,2025
#    EMPLOYEE_NAME,โด้-พัฒนพล
#    PROJECT_NAME,futureskill-b2b-learning-platform25
#    MORNING_WORK,Bug fix i18n content-panel repository
#    DAILY_WORK,Development class management II


# ---------------------------------------------- #


# ********❌  Note (อ่านก่อนเหยดแหม่ ❌ ******** #


# หา directory ที่ไฟล์นี้อยู่
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📁 Script directory: $SCRIPT_DIR"

# เข้า directory นั้น
cd "$SCRIPT_DIR" || { echo "❌ ไม่สามารถเข้า directory ได้"; exit 1; }

# 1. ตรวจสอบ Node.js และ npm
if ! command -v node &> /dev/null
then
    echo "❌ Node.js ไม่ได้ติดตั้ง กรุณาติดตั้ง Node.js ก่อน"
    exit 1
fi

echo "✅ พบ Node.js เวอร์ชัน: $(node -v)"
echo "✅ พบ npm เวอร์ชัน: $(npm -v)"

# 2. สร้าง package.json ถ้ายังไม่มี
if [ ! -f package.json ]; then
  npm init -y
  echo "✅ สร้าง package.json เรียบร้อย"
fi

# 3. สร้างโฟลเดอร์ node_modules ถ้ายังไม่มี
if [ ! -d "node_modules" ]; then
  echo "📁 ไม่พบ node_modules สร้างใหม่"
else
  echo "📁 พบ node_modules แล้ว"
fi

# 4. ตรวจสอบและติดตั้ง playwright
npm list playwright &> /dev/null
if [ $? -ne 0 ]; then
  echo "🔄 กำลังติดตั้ง playwright ..."
  npm install playwright
else
  echo "✅ พบแพ็กเกจ playwright แล้ว"
fi

# 5. ตรวจสอบและติดตั้ง date-fns
npm list date-fns &> /dev/null
if [ $? -ne 0 ]; then
  echo "🔄 กำลังติดตั้ง date-fns ..."
  npm install date-fns
else
  echo "✅ พบแพ็กเกจ date-fns แล้ว"
fi

CONFIG_FILE="config.csv"
SCRIPT_FILE="airtable_submit.mjs"

# 6. ตรวจสอบว่าไฟล์ config.csv มีอยู่ไหม
if [[ ! -f $CONFIG_FILE ]]; then
  echo "❌ Not found: $CONFIG_FILE"
  exit 1
fi

echo "📄 Found config: $CONFIG_FILE"

# 7. สร้าง airtable_submit.mjs โดยฝังโค้ด JavaScript ที่จะอ่าน config.csv ภายใน
cat << 'EOF' > "$SCRIPT_FILE"
import { readFileSync } from 'fs';
import { chromium } from 'playwright';
import { format, isWeekend } from 'date-fns';

const configText = readFileSync('./config.csv', 'utf-8');
const configLines = configText.trim().split('\n').slice(1); // skip header
const config = {};
for (const line of configLines) {
  const [key, ...rest] = line.split(',');
  const value = rest.join(',').trim(); // รองรับ value ที่มี , ได้
  if (key && value) config[key.trim()] = value;
}

// ตรวจสอบ config ที่จำเป็น
const REQUIRED_KEYS = ['START_DAY', 'END_DAY', 'START_MONTH', 'START_YEAR', 'EMPLOYEE_NAME', 'PROJECT_NAME'];
for (const key of REQUIRED_KEYS) {
  if (!config[key]) {
    console.error(`❌ Missing or empty required config key: ${key}`);
    process.exit(1);
  }
}

// แปลงค่าตัวเลขจาก string
const START_DAY = Number(config.START_DAY);
const END_DAY = Number(config.END_DAY);
const START_MONTH = Number(config.START_MONTH);
const START_YEAR = Number(config.START_YEAR);

const EMPLOYEE_NAME = config.EMPLOYEE_NAME;
const PROJECT_NAME = config.PROJECT_NAME;
const COMPANY = "FutureSkill";

const ACTIVITY_TYPE = {
  WEEKLY: 'Weekly Update Tech Team',
  RETRO: 'Sprint Retrospective',
  PLANNING: 'Sprint Planning',
  REVIEW: 'Sprint Review',
  DEPLOY: 'Recheck feature before deploy to production',
  DAILY_STANDUP: 'Daily Standup', 
  MORNING_WORK: config.MORNING_WORK || "ปรึกษากับ ux/ui ส่วนที่ต้องพัฒนาเพิ่มเติมของโปรเจค",
  LUNCH_BREAK: "พักเที่ยง",
  DAILY_WORK: config.DAILY_WORK || "อัพเดตความคืบหน้าของงานและระยะเวลาดำเนินงาน"
};

const SCHEDULE = {
  WEEKLY: { day: 2, frequency: 'every', hours: 1 },
  PLANNING: { day: 1, frequency: 'alternate', hours: 1 },
  DEPLOY: { day: 4, frequency: 'every', hours: 0.5 },
  RETRO: { day: 5, frequency: 'alternate', hours: 1 },
  REVIEW: { day: 5, frequency: 'alternate', hours: 1 },
  DAILY_STANDUP: { day: 'workdays', frequency: 'every', hours: 1 },
  MORNING_WORK: { day: 'workdays', frequency: 'every', hours: 1 },
  LUNCH_BREAK: { day: 'workdays', frequency: 'every', hours: 1 },
  DAILY_WORK: { day: 'workdays', frequency: 'every', hours: 1 }
};

const URL = "https://airtable.com/app6PjJAAPwiRw71N/pagWjJnFT2ZQn7eka/form";


/**
 * เช็คว่าวันนั้นๆ ต้องมีกิจกรรมอะไรบ้าง
 * @param {Date} date - วันที่ต้องการเช็ค
 * @param {Date} startDate - วันเริ่มต้นสำหรับคำนวณ alternate
 * @returns {Array} - array ของ activity types
 */
function getActivitiesForDay(date, startDate) {
  if (isWeekend(date)) {
    return [];
  }

  const activities = [];
  const dayOfWeek = date.getDay(); // 0=Sunday, 1=Monday, ..., 6=Saturday
  
  // คำนวณสัปดาห์สำหรับ alternate activities
  const weeksSinceStart = Math.floor((date - startDate) / (7 * 24 * 60 * 60 * 1000));
  const isEvenWeek = weeksSinceStart % 2 === 0;

  // เช็คแต่ละกิจกรรม
  for (const [type, schedule] of Object.entries(SCHEDULE)) {
    if (schedule.day === 'daily') {
      // ทุกวัน (รวมวันหยุด แต่เราจะ filter วันหยุดไว้แล้ว)
      activities.push(type);
    } else if (schedule.day === 'workdays') {
      // ทุกวันทำงาน
      activities.push(type);
    } else if (dayOfWeek === schedule.day) {
      if (schedule.frequency === 'every') {
        // ทุกสัปดาห์
        activities.push(type);
      } else if (schedule.frequency === 'alternate' && isEvenWeek) {
        // เว้นสัปดาห์ (สัปดาห์คู่)
        activities.push(type);
      }
    }
  }

  return activities;
}

/**
 * สร้าง task สำหรับ activity เดียว
 * @param {string} activity - activity type
 * @returns {Object} - { taskItem, taskNote, taskType, hours }
 */
function createTaskFromSingleActivity(activity) {
  const schedule = SCHEDULE[activity];
  
  let taskType;
  switch (activity) {
    case 'LUNCH_BREAK':
      taskType = 'Idle';
      break;
    case 'MORNING_WORK':
      taskType = 'Create / Do / Work';
      break;
    case 'DAILY_WORK':
      taskType = 'Create / Do / Work';
      break;
    default:
      taskType = 'Internal Meeting';
  }

  return {
    taskType,
    taskItem: ACTIVITY_TYPE[activity],
    taskNote: ACTIVITY_TYPE[activity],
    hours: schedule ? schedule.hours.toString() : '1'
  };
}

(async () => {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext({
    viewport: { width: 1250, height: 600 },
    userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36",
    // storageState: './trackingstate.json'
  });
  const page = await context.newPage();
  await page.goto(URL, { waitUntil: 'domcontentloaded' });

  console.log("Please login manually and press ENTER to continue...");
  await new Promise(resolve => process.stdin.once('data', resolve));

  // สร้าง workdays พร้อม activity schedule
  const workdays = [];
  const totalDays = END_DAY - START_DAY + 1;
  const startDate = new Date(START_YEAR, START_MONTH - 1, 1); // reference date

  for (let i = 0; i < totalDays; i++) {
    const currentDate = new Date(START_YEAR, START_MONTH - 1, START_DAY + i);
    console.log("day", currentDate);
    
    if (!isWeekend(currentDate)) {
      const activities = getActivitiesForDay(currentDate, startDate);
      
      // สร้าง task แยกสำหรับแต่ละ activity
      const dayTasks = [];
      if (activities.length === 0) {
        // ถ้าไม่มี activity ให้ใส่ Development
        dayTasks.push({
          activity: 'DEVELOPMENT',
          ...createTaskFromSingleActivity('DEVELOPMENT')
        });
      } else {
        // แยกแต่ละ activity เป็น task ต่างหาก
        activities.forEach(activity => {
          dayTasks.push({
            activity: activity,
            ...createTaskFromSingleActivity(activity)
          });
        });
      }

      workdays.push({
        date: format(currentDate, 'yyyy/M/dd'),
        dayName: format(currentDate, 'EEEE'),
        tasks: dayTasks
      });
    }
  }

  console.log('\n📅 Work Schedule:');
  workdays.forEach(day => {
    console.log(`\n${day.date} (${day.dayName}):`);
    day.tasks.forEach((task, index) => {
      console.log(`  ${index + 1}. Activity: ${task.activity} | Type: ${task.taskType} | Item: ${task.taskItem} | Hours: ${task.hours}h`);
    });
  });

  for (const dayData of workdays) {
    console.log(`\n🗓️ Starting ${dayData.date} (${dayData.dayName}) - ${dayData.tasks.length} tasks`);
    
    for (let taskIndex = 0; taskIndex < dayData.tasks.length; taskIndex++) {
      const task = dayData.tasks[taskIndex];
      console.log(`\n🔄 Processing Task ${taskIndex + 1}/${dayData.tasks.length}: ${task.activity} - ${task.taskItem} (${task.hours}h)...`);
      
      // รอให้หน้าโหลดเสร็จ
      await page.waitForLoadState('networkidle');
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

      // ส่งฟอร์ม
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

echo "🛠️ กำลังปรับรูปแบบวันที่ใน airtable_submit.mjs..."

# ตรวจสอบระบบปฏิบัติการ
OS_TYPE=$(uname)

# คำสั่ง sed ให้แก้ yyyy/M/dd → MM/dd/yyyy
if [[ "$OS_TYPE" == "Darwin" ]]; then
  # สำหรับ macOS
  sed -i '' "s/format(currentDate, 'yyyy\/M\/dd')/format(currentDate, 'MM\/dd\/yyyy')/g" "$SCRIPT_FILE"
elif [[ "$OS_TYPE" == "Linux" ]]; then
  # สำหรับ Linux
  sed -i "s/format(currentDate, 'yyyy\/M\/dd')/format(currentDate, 'MM\/dd\/yyyy')/g" "$SCRIPT_FILE"
else
  echo "❌ ไม่รองรับ OS นี้: $OS_TYPE"
  exit 1
fi

echo "✅ แก้ไข format วันที่ใน airtable_submit.mjs สำเร็จแล้ว"


# 7. รันสคริปต์
echo "🚀 กำลังรันสคริปต์..."
node "$SCRIPT_FILE"

echo "✅ เสร็จสิ้น!"