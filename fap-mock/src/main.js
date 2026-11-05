import csvText from '../../mobile/sample-data/lop-fall-2026.csv?raw';
import { parseClasses, sessionsFor, todayVn } from './roster.js';
import { createAttendanceRow } from './attendance-row.js';

const rows = document.querySelector('#attendance-rows');
const receipt = document.querySelector('#save-status');
const form = document.querySelector('#aspnetForm');
const picker = document.querySelector('#today-class');
const notice = document.querySelector('#no-class-notice');
const dateInput = document.querySelector('#session-date');
const classes = parseClasses(csvText);
let selectedClass = null;
const slotNumber = (slotCode) => Number(slotCode.slice(-1));
const storageKey = () => selectedClass === null ? null : `fap-fixture-v2:${selectedClass.campus ?? 'FU-HCM'}:${selectedClass.courseCode}:${selectedClass.groupCode}:${selectedClass.sessionDate}:${slotNumber(selectedClass.slotCode)}`;
const snapshot = () => [...rows.rows].map(row => ({ studentCode: row.cells[2].textContent.trim(), status: row.querySelector('input[value="rdPresent"]').checked ? 'ATTEND' : 'ABSENT' }));
function summary() {
  const present = snapshot().filter(x => x.status === 'ATTEND').length;
  document.querySelector('#selection-summary').textContent = `${present} present · ${rows.rows.length - present} absent`;
}
function dirty() { summary(); receipt.textContent = 'Có thay đổi chưa lưu trong bản giả lập.'; delete receipt.dataset.savedSnapshot; delete receipt.dataset.saveError; }
function save() {
  const key = storageKey(); if (key === null) return;
  try {
    const value = JSON.stringify(snapshot()); sessionStorage.setItem(key, value);
    if (sessionStorage.getItem(key) !== value) throw new Error('Storage unavailable');
    receipt.dataset.savedSnapshot = value; delete receipt.dataset.saveError; receipt.textContent = 'Đã lưu bản giả lập trong tab này. Không gửi dữ liệu lên FAP.';
  } catch { delete receipt.dataset.savedSnapshot; receipt.dataset.saveError = 'storage'; receipt.textContent = 'Không lưu được: trình duyệt đang chặn lưu trữ. Dữ liệu trên bảng chưa được lưu.'; }
}
function formatFixtureDate(value) { const [year, month, day] = value.split('-'); return `${day}/${month}/${year}`; }
function weekday(value) { return new Intl.DateTimeFormat('en-US', { weekday: 'long', timeZone: 'Asia/Ho_Chi_Minh' }).format(new Date(`${value}T12:00:00+07:00`)); }
function renderClass(item) {
  selectedClass = item;
  document.querySelector('#ctl00_lblCampusName').textContent = item.campus ?? 'FU-HCM';
  document.querySelector('#ctl00_mainContent_gvAttendance').dataset.course = item.courseCode;
  document.querySelector('#ctl00_mainContent_gvAttendance').dataset.sessionId = item.sessionId ?? '';
  document.querySelector('#attendance-title').innerHTML = `Attendance for <b>Lecturer Demo</b> at slot ${slotNumber(item.slotCode)} on ${weekday(item.sessionDate)} ${formatFixtureDate(item.sessionDate)} at room ${item.room ?? 'TBA'}.This is the session number ${item.sessionNumber ?? 1} of the course.`;
  document.querySelector('#class-summary').innerHTML = `${item.courseCode} · ${item.groupCode} · <b id="visible-count">${item.students.length}</b> / ${item.rosterCount} sinh viên`;
  rows.replaceChildren(...item.students.map((student, index) => createAttendanceRow(document, { ...student, group: item.groupCode }, index)));
  receipt.textContent = 'Chưa lưu bản giả lập.';
  const key = storageKey();
  try {
    const saved = JSON.parse(sessionStorage.getItem(key) ?? 'null');
    if (saved !== null) {
      if (!Array.isArray(saved) || saved.length !== rows.rows.length || saved.some((entry, index) => entry.studentCode !== rows.rows[index].cells[2].textContent.trim() || !['ATTEND', 'ABSENT'].includes(entry.status))) throw new Error('Invalid snapshot');
      saved.forEach((entry, index) => { rows.rows[index].querySelector(`input[value="${entry.status === 'ATTEND' ? 'rdPresent' : 'rdAbsent'}"]`).checked = true; });
      receipt.dataset.savedSnapshot = JSON.stringify(saved); receipt.textContent = 'Đã khôi phục bản giả lập đã lưu trong tab này.';
    }
  } catch { receipt.textContent = 'Không đọc được bản lưu. Đang dùng dữ liệu mẫu ban đầu.'; }
  summary();
}
function showNoClasses(message) {
  selectedClass = null; rows.replaceChildren(); form.hidden = true; picker.disabled = true;
  document.querySelector('#class-summary').textContent = 'Không có dữ liệu lớp hôm nay'; document.querySelector('#attendance-title').textContent = message; notice.hidden = false;
}
// Không có máy chủ: lịch lấy từ file mẫu. Chọn ngày rồi chọn buổi; buổi đúng thứ của ngày đứng đầu.
function loadDay(date) {
  const available = sessionsFor(classes, date);
  if (available.length === 0) return showNoClasses('File mẫu không có lớp nào.');
  picker.replaceChildren(...available.map((item, index) => { const option = document.createElement('option'); option.value = String(index); option.textContent = `${item.courseCode} · ${item.groupCode} · Slot ${slotNumber(item.slotCode)} · ${item.room ?? 'TBA'}${item.scheduled ? '' : ' (ngoài lịch)'}`; return option; }));
  picker.disabled = false; form.hidden = false; notice.hidden = true; picker.onchange = () => renderClass(available[Number(picker.value)]); renderClass(available[0]);
}
rows.addEventListener('change', dirty); document.addEventListener('fap-fixture-change', dirty); document.addEventListener('fap-fixture-save', save);
form.addEventListener('submit', event => { event.preventDefault(); save(); });
document.querySelector('#reset-mock').addEventListener('click', () => {
  const key = storageKey(); if (key === null) return;
  try { sessionStorage.removeItem(key); } catch { receipt.textContent = 'Không xóa được bản lưu. Kiểm tra quyền lưu trữ.'; return; }
  for (const row of rows.rows) row.querySelector('input[value="rdAbsent"]').checked = true; dirty();
});
document.querySelector('#student-search').addEventListener('input', event => {
  let visible = 0;
  for (const row of rows.rows) { row.hidden = !row.textContent.toLocaleLowerCase('vi').includes(event.target.value.trim().toLocaleLowerCase('vi')); if (!row.hidden) visible++; }
  document.querySelector('#visible-count').textContent = String(visible);
});
document.querySelector('#show-images').addEventListener('change', event => document.body.classList.toggle('show-images', event.target.checked));
dateInput.value = todayVn();
dateInput.addEventListener('change', () => { if (dateInput.value) loadDay(dateInput.value); });
loadDay(dateInput.value);
