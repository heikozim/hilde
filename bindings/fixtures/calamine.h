/*
 * The C interface of the calamine bridge, as Diplomat writes it for the
 * Rust module in rust/calamine-bridge.  A workbook is one opaque object
 * the caller owns and frees once; the calls that read it take the
 * pointer const and leave the object with the caller, the call that
 * opens one takes the object and gives it back, and every string is
 * copied into a buffer of the caller, so no memory of Rust reaches
 * Hilde.
 *
 * A file the crate cannot read is no abort and no null pointer: the
 * open fails and the error code is read with calamine_error.
 */
#ifndef HILDE_CALAMINE_H
#define HILDE_CALAMINE_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

typedef struct CalamineSheet CalamineSheet;

/* The bytes of a file, as the caller holds them.  The crate reads them
   and keeps nothing of them. */
typedef struct {
    const char *data;
    size_t len;
} CalamineBytes;

/* One cell.  kind says which field is live: 0 empty, 1 text, 2 float,
   3 integer, 4 truth value, 5 error, 6 date and time as its serial
   number in float_value.  A text cell is read with calamine_cell_text. */
typedef struct {
    int32_t kind;
    int32_t int_value;
    double float_value;
    bool bool_value;
} CalamineCell;

/* Makes a sheet that has opened no workbook yet.  The caller owns it
   and frees it with calamine_destroy. */
CalamineSheet *calamine_new(void);

/* Reads the workbook of the bytes and gives the object back.  The
   error code of the call is read with calamine_error; it is 0 when the
   bytes were a workbook. */
CalamineSheet *calamine_open(CalamineSheet *sheet, CalamineBytes bytes);

/* The error code of the last call that failed, 0 after one that did
   not. */
int32_t calamine_error(const CalamineSheet *sheet);

/* The number of sheets of the workbook. */
size_t calamine_sheet_count(const CalamineSheet *sheet);

/* The name of the sheet at index, copied into out, at most out_len
   bytes, and the number of bytes written. */
size_t calamine_sheet_name(const CalamineSheet *sheet, size_t index,
                           char *out, size_t out_len);

/* The number of rows of the sheet at index. */
size_t calamine_sheet_rows(const CalamineSheet *sheet, size_t index);

/* The number of columns of the sheet at index. */
size_t calamine_sheet_columns(const CalamineSheet *sheet, size_t index);

/* The cell at row and column of the sheet at index. */
CalamineCell calamine_cell(const CalamineSheet *sheet, size_t index,
                           size_t row, size_t column);

/* The text of the cell at row and column, copied into out, at most
   out_len bytes, and the number of bytes written; 0 for a cell that is
   no text. */
size_t calamine_cell_text(const CalamineSheet *sheet, size_t index,
                          size_t row, size_t column, char *out,
                          size_t out_len);

/* Frees the object.  The sheet is gone with it. */
void calamine_destroy(CalamineSheet *sheet);

#endif
