import Papa from 'papaparse';
import readExcelFile from 'read-excel-file/browser';

import type { SourceBatch } from '../attendance';
import { GridError, parseAttendanceGrid, type ParsedGrid } from '../grid';

const BOM = new RegExp(`^${String.fromCharCode(0xfeff)}`);

export const MAX_FILE_BYTES = 2 * 1024 * 1024;
export const ACCEPTED_FILE_TYPES = '.csv,.tsv,.txt,.xlsx';

function extension(name: string): string {
  return name.toLowerCase().split('.').pop() ?? '';
}

export function parseDelimitedText(text: string): string[][] {
  const result = Papa.parse<string[]>(text.replace(BOM, ''), {
    skipEmptyLines: 'greedy',
    delimitersToGuess: [',', ';', '\t'],
  });
  if (result.errors.some((error) => error.type === 'Quotes')) {
    throw new GridError('Tệp CSV có dấu ngoặc kép không đóng.');
  }
  return result.data;
}

/** First sheet whose header is recognizable wins; errors from the others are not shown. */
async function parseWorkbook(file: File): Promise<ParsedGrid> {
  const sheets = await readExcelFile(file);
  let firstError: unknown;
  for (const sheet of sheets) {
    try {
      return parseAttendanceGrid(sheet.data);
    } catch (error) {
      firstError ??= error;
    }
  }
  throw firstError instanceof Error ? firstError : new GridError('Tệp Excel không có trang tính.');
}

export async function readAttendanceFile(file: File): Promise<SourceBatch> {
  if (file.size > MAX_FILE_BYTES) throw new GridError('Tệp lớn hơn 2 MB.');
  const type = extension(file.name);
  let parsed: ParsedGrid;
  if (type === 'xlsx') parsed = await parseWorkbook(file);
  else if (['csv', 'tsv', 'txt'].includes(type)) {
    parsed = parseAttendanceGrid(parseDelimitedText(await file.text()));
  } else {
    throw new GridError('Chỉ hỗ trợ tệp .csv, .tsv hoặc .xlsx.');
  }
  return { kind: 'file', label: file.name, context: parsed.context, rows: parsed.rows };
}
