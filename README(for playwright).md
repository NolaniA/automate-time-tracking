# 🤖 Automated Timesheet Submission Tool

เครื่องมือสำหรับการส่งข้อมูล timesheet ไปยัง Airtable อัตโนมัติ โดยใช้ Playwright (macOS/Linux)เพื่อกรอกฟอร์มอัตโนมัติ

## 📋 Requirements

- **Node.js** เวอร์ชัน 18+ (https://nodejs.org/)
- **npm** (มาพร้อม Node.js)
- **Internet connection** (สำหรับ Airtable)

## 📁 Files ที่จำเป็น

```
project/
├── timesheet.sh                     # Script หลัก (macOS/Linux)
├── config.csv                       # การตั้งค่าพื้นฐาน
├── daily_tasks.json                 # งานเฉพาะวัน
├── scheduled_activities.json        # ประชุม/กิจกรรมประจำ
├── README.md                        # คู่มือนี้
├── package.json                     # (สร้างอัตโนมัติ)
├── node_modules/                    # (สร้างอัตโนมัติ)
└── airtable_submit.mjs             # (สร้างอัตโนมัติ)
```

## 🚀 วิธีใช้งาน

### **macOS/Linux:**

```bash
# 1. ให้สิทธิ์ execute
chmod +x timesheet.sh

# 2. รันสคริปต์
./timesheet.sh

# 3. Login เข้า Airtable ด้วยตนเอง เมื่อ browser เปิด
# 4. กด Enter ใน terminal เพื่อเริ่มการทำงาน
```

## ⚙️ การตั้งค่า

### 1. **config.csv** - การตั้งค่าพื้นฐาน

```csv
key,value
START_DAY,29
END_DAY,31
START_MONTH,7
START_YEAR,2025
EMPLOYEE_NAME,ชื่อเล่น-ชื่อจริง
PROJECT_NAME,futureskill-b2b-learning-platform25
COMPANY,FutureSkill
```

**หมายเหตุ:** มีการ skip weekend ไว้แล้ว สามารถใส่วันโดยไม่ต้องคำนึงถึง weekend

### 2. **daily_tasks.json** - งานเฉพาะวัน

สำหรับงานที่ไม่ใช่ Lutein ในแต่ละวัน อาจมีซ้ำหรือไม่ซ้ำก็ได้

```json
{
  "2025-07-01": [
    {
      "task": "Fix authentication bug in login module",
      "type": "work",
      "hours": "2"
    },
    {
      "task": "Code review for pull request #123",
      "type": "audit",
      "hours": "1"
    }
  ],
  "2025-07-02": [
    {
      "task": "Fix authentication bug in login module",
      "type": "work",
      "hours": "2"
    },
    {
      "task": "Code review for pull request #123",
      "type": "audit",
      "hours": "1"
    }
  ], ... ,
  "2025-07-31": [
    {
      "task": "Research new React optimization techniques",
      "type": "plan",
      "hours": "3"
    }
  ]
}
```

**หมายเหตุ:**

- format ของวันที่ต้องเป็น yyyy/mm/dd เท่านั้น ❌ 2025-07-1 ✅2025-07-01
- ไม่จำเป็นต้องมี "default" หากวันไหนไม่มี daily_tasks ก็จะทำแค่ scheduled activities พอ

**Task Types ที่รองรับ:**

- `"work"` = Create / Do / Work
- `"audit"` = Audit Work
- `"plan"` = Plan / Think
- `"coordinate"` = Co-Ordinate
- `"meeting"` = Internal Meeting
- `"idle"` = Idle
- `"leave"` = Leave
- `"other"` = Other

### 3. **scheduled_activities.json** - ประชุม/กิจกรรมประจำ

**⚠️ Warning:**scheduled_activities มีไว้เพื่อทำ task ที่เป็น Lutein หากไม่ใช่อะไรที่ทำเป็น Lutein จริงๆ ไปทำใน daily_tasks จะตอบโจทย์กว่า

```json
{
  "activities": {
    "WEEKLY": "Weekly Update Tech Team",
    "RETRO": "Sprint Retrospective",
    "PLANNING": "Sprint Planning",
    "REVIEW": "Sprint Review",
    "DEPLOY": "Recheck feature before deploy to production",
    "DAILY_STANDUP": "Daily Standup",
    "LUNCH_BREAK": "พักเที่ยง"
  },
  "schedule": {
    "WEEKLY": { "day": 2, "frequency": "every", "hours": 1 },
    "PLANNING": { "day": 1, "frequency": "alternate", "hours": 1 },
    "DEPLOY": { "day": 4, "frequency": "every", "hours": 0.5 },
    "RETRO": { "day": 5, "frequency": "alternate", "hours": 1 },
    "REVIEW": { "day": 5, "frequency": "alternate", "hours": 1 },
    "DAILY_STANDUP": { "day": "workdays", "frequency": "every", "hours": 1 },
    "LUNCH_BREAK": { "day": "workdays", "frequency": "every", "hours": 1 }
  }
}
```

**หมายเหตุ:**

- หากต้องการเพิ่ม activities และ schedule ให้เพิ่ม switch case เพื่อกำหนด taskType ที่ function createTaskFromActivity โดยใช้ activities เป็น case

**คำอธิบาย Schedule:**

- **day:** `1`=จันทร์, `2`=อังคาร, `3`=พุธ, `4`=พฤหัส, `5`=ศุกร์ หรือ `"workdays"`
- **frequency:** `"every"`=ทุกสัปดาห์ หรือ `"alternate"`=เว้นสัปดาห์

## 📊 ตัวอย่างผลลัพธ์

```
📅 Work Schedule:

07/29/2025 (Monday):
  📅 1. DAILY_STANDUP | Type: Internal Meeting | Hours: 1h
  📅 2. LUNCH_BREAK | Type: Idle | Hours: 1h
  💻 3. DAILY_WORK_1 | Type: Create / Do / Work | Fix authentication bug | Hours: 2h
  💻 4. DAILY_WORK_2 | Type: Audit Work | Code review for pull request #123 | Hours: 1h
  🕐 Total hours: 5h

07/30/2025 (Tuesday):
  📅 1. DAILY_STANDUP | Type: Internal Meeting | Hours: 1h
  📅 2. WEEKLY | Type: Internal Meeting | Hours: 1h
  📅 3. LUNCH_BREAK | Type: Idle | Hours: 1h
  🕐 Total hours: 3h
```

## 🛠️ Troubleshooting

### **ปัญหา Node.js ไม่ได้ติดตั้ง:**

```bash
# macOS (with Homebrew)
brew install node

# Ubuntu/Debian
sudo apt install nodejs npm

```

### **ปัญหา Permission denied (macOS/Linux):**

```bash
chmod +x timesheet.sh
# หรือ
sudo chmod +x timesheet.sh
```

### **ปัญหา Dependencies ไม่ได้ติดตั้ง:**

```bash
# ลบและติดตั้งใหม่
rm -rf node_modules package-lock.json
npm install playwright date-fns

# หรือติดตั้ง manual
npm install playwright --save
npm install date-fns --save
```

### **ปัญหา Playwright browsers:**

```bash
# ติดตั้ง browsers สำหรับ Playwright
npx playwright install
```

### **ปัญหา UTF-8 บน Windows:**

```cmd
# เปิด Command Prompt แล้วรัน
chcp 65001
```

## 🎯 Features

### ✅ **Smart Scheduling System**

- คำนวณกิจกรรมตามวันในสัปดาห์
- รองรับการทำงานแบบ "เว้นสัปดาห์"
- ข้ามวันหยุดสุดสัปดาห์อัตโนมัติ

### ✅ **JSON Configuration System**

- แยกการตั้งค่าออกจากโค้ด
- แก้ไขได้ง่าย ไม่ต้องแก้โค้ด
- รองรับ task หลายประเภท

### ✅ **Error Handling**

- ตรวจสอบ dependencies ก่อนรัน
- รอให้ element ปรากฏก่อนทำงาน
- มี timeout สำหรับการรอ

### ✅ **User-friendly**

- แสดงสถานะการทำงานแบบ real-time
- ให้ user login manually ก่อน
- แสดงสรุปชั่วโมงทำงานแต่ละวัน

## 📞 Support

หากมีปัญหาการใช้งาน สามารถ:

1. ตรวจสอบ error message ใน terminal
2. ดู troubleshooting section ในคู่มือนี้
3. ตรวจสอบว่าไฟล์ config ถูกต้อง
4. ลองรัน script ใหม่อีกครั้ง

---
