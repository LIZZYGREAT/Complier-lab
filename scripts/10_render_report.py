#!/usr/bin/env python3
"""Render the Markdown report to a self-contained, paginated PDF using stdlib."""

from __future__ import annotations

import hashlib
import math
import re
import sys
import unicodedata
from pathlib import Path


LAB_DIR = Path(__file__).resolve().parents[1]
SOURCE = LAB_DIR / "report" / "report.md"
OUTPUT = LAB_DIR / "report" / "report.pdf"
PAGE_W = 595.28
PAGE_H = 841.89
LEFT = 50.0
RIGHT = 50.0
CONTENT_W = PAGE_W - LEFT - RIGHT
BODY_BOTTOM = 55.0


def clean_inline(text: str) -> str:
    text = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"`([^`]*)`", r"\1", text)
    text = text.replace("**", "").replace("__", "")
    text = text.replace("*", "")
    return text.strip()


def char_width(ch: str, size: float) -> float:
    if ch == " ":
        return size * 0.28
    if ord(ch) <= 0x7F:
        if ch in "il.,:;!'|`":
            return size * 0.28
        if ch in "MW@%&":
            return size * 0.82
        return size * 0.52
    if unicodedata.east_asian_width(ch) in "WF":
        return size
    return size * 0.58


def text_width(text: str, size: float) -> float:
    return sum(char_width(ch, size) for ch in text)


def wrap_text(text: str, max_width: float, size: float) -> list[str]:
    text = clean_inline(text)
    if not text:
        return [""]
    lines: list[str] = []
    line = ""
    line_width = 0.0
    last_space = -1
    for ch in text:
        width = char_width(ch, size)
        if line and line_width + width > max_width:
            if last_space >= 0:
                lines.append(line[:last_space].rstrip())
                carry = line[last_space + 1 :].lstrip()
                line = carry
                line_width = text_width(carry, size)
            else:
                lines.append(line.rstrip())
                line = ""
                line_width = 0.0
            last_space = line.rfind(" ")
        line += ch
        line_width += width
        if ch.isspace():
            last_space = len(line) - 1
    if line.strip():
        lines.append(line.rstrip())
    return lines or [""]


def parse_markdown(path: Path) -> list[tuple[str, object]]:
    lines = path.read_text(encoding="utf-8").splitlines()
    blocks: list[tuple[str, object]] = []
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if not line:
            i += 1
            continue
        if line.startswith("```"):
            i += 1
            code: list[str] = []
            while i < len(lines) and not lines[i].strip().startswith("```"):
                code.append(lines[i].rstrip())
                i += 1
            blocks.append(("code", code))
            i += 1
            continue
        if line.startswith("![") and line.endswith(")"):
            match = re.match(r"!\[(.*?)\]\((.*?)\)", line)
            if match:
                kind = "figure_pipeline" if match.group(2) == "pipeline" else "figure_cfg"
                blocks.append((kind, clean_inline(match.group(1))))
                i += 1
                continue
        if line.startswith("# "):
            blocks.append(("title", clean_inline(line[2:])))
            i += 1
            continue
        if line.startswith("## "):
            blocks.append(("h2", clean_inline(line[3:])))
            i += 1
            continue
        if line.startswith("### "):
            blocks.append(("h3", clean_inline(line[4:])))
            i += 1
            continue
        if line.startswith("| "):
            rows: list[list[str]] = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                cells = [clean_inline(c.strip()) for c in lines[i].strip().strip("|").split("|")]
                if not all(re.fullmatch(r"[:\-\s]+", c or "-") for c in cells):
                    rows.append(cells)
                i += 1
            if rows:
                blocks.append(("table", rows))
            continue
        if line.startswith("- "):
            blocks.append(("bullet", clean_inline(line[2:])))
            i += 1
            continue
        paragraph = [line]
        i += 1
        while i < len(lines):
            nxt = lines[i].strip()
            if (
                not nxt
                or nxt.startswith(("# ", "## ", "### ", "| ", "- ", "```", "!["))
            ):
                break
            paragraph.append(nxt)
            i += 1
        blocks.append(("paragraph", clean_inline(" ".join(paragraph))))
    return blocks


def pdf_hex(text: str) -> str:
    data = text.encode("utf-16-be")
    if len(data) % 2:
        raise ValueError("odd UTF-16BE string length")
    return data.hex().upper()


def build_tounicode(codepoints: set[int]) -> bytes:
    chunks = [
        "/CIDInit /ProcSet findresource begin",
        "12 dict begin",
        "begincmap",
        "/CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def",
        "/CMapName /CompilerLabs-UCS def",
        "/CMapType 2 def",
        "1 begincodespacerange",
        "<0000> <FFFF>",
        "endcodespacerange",
    ]
    points = sorted(cp for cp in codepoints if 0 <= cp <= 0xFFFF)
    for start in range(0, len(points), 100):
        part = points[start : start + 100]
        chunks.append(f"{len(part)} beginbfchar")
        for cp in part:
            encoded = f"{cp:04X}"
            chunks.append(f"<{encoded}> <{encoded}>")
        chunks.append("endbfchar")
    chunks.extend(["endcmap", "CMapName currentdict /CMap defineresource pop", "end", "end"])
    return "\n".join(chunks).encode("ascii")


class PDFLayout:
    def __init__(self) -> None:
        self.pages: list[list[str]] = []
        self.commands: list[str] = []
        self.y = 0.0
        self.used_codepoints: set[int] = set()
        self.new_page()

    def add(self, command: str) -> None:
        self.commands.append(command)

    def add_text(self, x: float, y: float, text: str, size: float, color=(0.12, 0.15, 0.20)) -> None:
        if not text:
            return
        self.used_codepoints.update(ord(ch) for ch in text if ord(ch) > 0x7F)
        self.add(f"{color[0]:.3f} {color[1]:.3f} {color[2]:.3f} rg")
        runs: list[tuple[bool, str]] = []
        is_cjk = ord(text[0]) > 0x7F
        run = text[0]
        for ch in text[1:]:
            current = ord(ch) > 0x7F
            if current == is_cjk:
                run += ch
            else:
                runs.append((is_cjk, run))
                is_cjk, run = current, ch
        runs.append((is_cjk, run))
        cursor_x = x
        for cjk, part in runs:
            if cjk:
                self.add(f"BT /F2 {size:.2f} Tf 1 0 0 1 {cursor_x:.2f} {y:.2f} Tm <{pdf_hex(part)}> Tj ET")
            else:
                self.add(f"BT /F1 {size:.2f} Tf 1 0 0 1 {cursor_x:.2f} {y:.2f} Tm <{part.encode('ascii', 'replace').hex().upper()}> Tj ET")
            cursor_x += text_width(part, size)

    def new_page(self) -> None:
        if self.commands:
            self.pages.append(self.commands)
        self.commands = []
        self.add("q 0.10 0.30 0.48 rg 50 806 495.28 1.2 re f Q")
        self.y = 782.0

    def ensure_space(self, height: float) -> None:
        if self.y - height < BODY_BOTTOM:
            self.new_page()

    def line(self, x1: float, y1: float, x2: float, y2: float, color=(0.40, 0.47, 0.54), width=0.8) -> None:
        self.add(f"q {color[0]:.3f} {color[1]:.3f} {color[2]:.3f} RG {width:.2f} w {x1:.2f} {y1:.2f} m {x2:.2f} {y2:.2f} l S Q")

    def arrow(self, x1: float, y1: float, x2: float, y2: float, color=(0.12, 0.30, 0.48)) -> None:
        self.line(x1, y1, x2, y2, color, 1.0)
        angle = math.atan2(y2 - y1, x2 - x1)
        length = 5.5
        spread = 0.48
        p1 = (x2 - length * math.cos(angle - spread), y2 - length * math.sin(angle - spread))
        p2 = (x2 - length * math.cos(angle + spread), y2 - length * math.sin(angle + spread))
        self.line(x2, y2, p1[0], p1[1], color, 1.0)
        self.line(x2, y2, p2[0], p2[1], color, 1.0)

    def box(self, x: float, top: float, width: float, height: float, label: str, size=7.7) -> None:
        bottom = top - height
        self.add(f"q 0.91 0.95 0.98 rg 0.22 0.38 0.52 RG 0.8 w {x:.2f} {bottom:.2f} {width:.2f} {height:.2f} re B Q")
        lines = label.split("\n")
        leading = size + 2.0
        first_y = bottom + (height + (len(lines) - 1) * leading) / 2.0 - size * 0.35
        for idx, line in enumerate(lines):
            self.add_text(x + max(3.0, (width - text_width(line, size)) / 2.0), first_y + (len(lines) - 1 - idx) * leading, line, size, (0.08, 0.17, 0.26))

    def centered_lines(self, center_x: float, first_y: float, lines: list[str], size: float, leading: float, color=(0.20, 0.24, 0.28)) -> None:
        for idx, line in enumerate(lines):
            self.add_text(center_x - text_width(line, size) / 2.0, first_y - idx * leading, line, size, color)

    def draw_pipeline(self, caption: str) -> None:
        self.ensure_space(125.0)
        self.y -= 8.0
        labels = ["SysY/C\n源文件", "预处理\n.i", "LLVM IR\n.ll", "汇编/目标\n.s/.o", "显式链接\nELF", "执行\nhost/QEMU"]
        box_w, box_h, gap = 72.0, 45.0, 10.0
        total = len(labels) * box_w + (len(labels) - 1) * gap
        x0 = (PAGE_W - total) / 2.0
        top = self.y - 12.0
        for idx, label in enumerate(labels):
            x = x0 + idx * (box_w + gap)
            self.box(x, top, box_w, box_h, label, 7.3)
            if idx < len(labels) - 1:
                self.arrow(x + box_w + 1.5, top - box_h / 2.0, x + box_w + gap - 1.5, top - box_h / 2.0)
        self.y = top - box_h - 17.0
        self.add_text(LEFT, self.y, caption, 8.5, (0.23, 0.30, 0.37))
        self.y -= 23.0

    def draw_cfg(self, caption: str) -> None:
        self.ensure_space(335.0)
        self.y -= 8.0
        top = self.y - 5.0
        w, h = 118.0, 42.0
        entry_x = 238.0
        cond_x = 205.0
        exit_x = 372.0
        if_x = 205.0
        then_x = 50.0
        else_x = 345.0
        merge_x = 205.0
        entry_t = top - 4.0
        cond_t = top - 60.0
        exit_t = cond_t
        if_t = top - 119.0
        branch_t = top - 180.0
        merge_t = top - 244.0
        self.box(entry_x, entry_t, w, h, "entry\n初始化 i、sum")
        self.box(cond_x, cond_t, w, h, "while 条件\ni <= n")
        self.box(exit_x, exit_t, w, h, "while.end\nreturn sum")
        self.box(if_x, if_t, w, h, "if 条件\ni % 2 == 0")
        self.box(then_x, branch_t, w, h, "if.then\nsum += 2*i")
        self.box(else_x, branch_t, w, h, "if.else\nsum += i")
        self.box(merge_x, merge_t, w, h, "if.end\ni++")

        entry_bottom = entry_t - h
        cond_top = cond_t
        self.arrow(entry_x + w / 2, entry_bottom, cond_x + w / 2, cond_top)
        cond_mid = cond_t - h / 2
        exit_mid = exit_t - h / 2
        self.arrow(cond_x + w, cond_mid, exit_x, exit_mid)
        self.centered_lines(cond_x + w + 25, cond_mid + 4, ["i > n"], 7.3, 9.0)
        self.arrow(cond_x + w / 2, cond_t - h, if_x + w / 2, if_t)

        if_mid = if_t - h / 2
        then_mid = branch_t - h / 2
        else_mid = then_mid
        self.arrow(if_x, if_mid, then_x + w, then_mid)
        self.arrow(if_x + w, if_mid, else_x, else_mid)
        self.centered_lines(then_x + w + 2, (if_mid + then_mid) / 2 + 7, ["偶数"], 7.1, 8.0)
        self.centered_lines(else_x - 1, (if_mid + else_mid) / 2 + 7, ["奇数"], 7.1, 8.0)
        self.arrow(then_x + w / 2, branch_t - h, merge_x + 20, merge_t)
        self.arrow(else_x + w / 2, branch_t - h, merge_x + w - 20, merge_t)

        merge_mid = merge_t - h / 2
        left_loop_x = 85.0
        cond_left = cond_x
        self.line(merge_x, merge_mid, left_loop_x, merge_mid, (0.12, 0.30, 0.48), 1.0)
        self.line(left_loop_x, merge_mid, left_loop_x, cond_mid, (0.12, 0.30, 0.48), 1.0)
        self.arrow(left_loop_x, cond_mid, cond_left, cond_mid)
        self.centered_lines(left_loop_x + 2, (merge_mid + cond_mid) / 2, ["回边"], 7.1, 8.0)

        self.y = merge_t - h - 15.0
        self.add_text(LEFT, self.y, caption, 8.5, (0.23, 0.30, 0.37))
        self.y -= 23.0

    def draw_heading(self, kind: str, text: str) -> None:
        if kind == "title":
            self.ensure_space(90.0)
            self.y -= 18.0
            size = 19.0
            self.add_text((PAGE_W - text_width(text, size)) / 2, self.y, text, size, (0.08, 0.20, 0.35))
            self.y -= 30.0
            return
        if kind == "h2":
            self.ensure_space(40.0)
            self.y -= 7.0
            self.add_text(LEFT, self.y, text, 13.2, (0.10, 0.30, 0.50))
            self.y -= 19.0
            return
        self.ensure_space(29.0)
        self.y -= 4.0
        self.add_text(LEFT, self.y, text, 11.0, (0.15, 0.35, 0.52))
        self.y -= 15.0

    def draw_paragraph(self, text: str, bullet=False, code=False) -> None:
        size = 8.8 if code else (9.6 if bullet else 10.0)
        leading = 12.0 if code else (14.0 if bullet else 15.2)
        indent = 15.0 if bullet else 0.0
        available = CONTENT_W - indent
        lines = wrap_text(text, available - (8.0 if code else 0.0), size)
        block_h = len(lines) * leading + (8.0 if code else 1.0)
        self.ensure_space(block_h + 2.0)
        if code:
            self.add(f"q 0.96 0.97 0.98 rg 49 {self.y - block_h + 2:.2f} {CONTENT_W:.2f} {block_h:.2f} re f Q")
        for idx, line in enumerate(lines):
            self.y -= leading
            x = LEFT + indent + (7.0 if code else 0.0)
            if bullet and idx == 0:
                self.add_text(LEFT + 2, self.y, "-", size, (0.12, 0.35, 0.55))
            self.add_text(x, self.y, line, size, (0.18, 0.20, 0.22))
        self.y -= 7.0 if code else 4.0

    def table_widths(self, headers: list[str]) -> list[float]:
        count = len(headers)
        if count == 5:
            return [55.0, 105.0, 105.0, 140.0, CONTENT_W - 405.0]
        if count == 3 and headers and headers[0] == "阶段":
            return [68.0, 170.0, CONTENT_W - 238.0]
        if count == 3 and headers and headers[0] == "源程序结构":
            return [105.0, 115.0, CONTENT_W - 220.0]
        if count == 2 and headers and headers[0].startswith("寄存器"):
            return [90.0, CONTENT_W - 90.0]
        return [CONTENT_W / count] * count

    def draw_table(self, rows: list[list[str]]) -> None:
        headers = rows[0]
        widths = self.table_widths(headers)
        size = 8.1
        leading = 10.2
        pad_x, pad_y = 5.0, 4.0

        def draw_row(row: list[str], row_index: int) -> float:
            nonlocal widths
            cell_lines = [wrap_text(row[j] if j < len(row) else "", widths[j] - 2 * pad_x, size) for j in range(len(widths))]
            row_h = max(len(lines) for lines in cell_lines) * leading + 2 * pad_y
            self.ensure_space(row_h + 2.0)
            if row_index == 0:
                self.add(f"q 0.12 0.30 0.48 rg {LEFT:.2f} {self.y-row_h:.2f} {CONTENT_W:.2f} {row_h:.2f} re f Q")
            elif row_index % 2 == 0:
                self.add(f"q 0.96 0.97 0.98 rg {LEFT:.2f} {self.y-row_h:.2f} {CONTENT_W:.2f} {row_h:.2f} re f Q")
            x = LEFT
            for col, width in enumerate(widths):
                self.add(f"q 0.72 0.76 0.80 RG 0.45 w {x:.2f} {self.y-row_h:.2f} {width:.2f} {row_h:.2f} re S Q")
                color = (1.0, 1.0, 1.0) if row_index == 0 else (0.18, 0.20, 0.22)
                for line_idx, line in enumerate(cell_lines[col]):
                    line_y = self.y - pad_y - size - line_idx * leading
                    self.add_text(x + pad_x, line_y, line, size, color)
                x += width
            self.y -= row_h
            return row_h

        self.ensure_space(30.0)
        for row_index, row in enumerate(rows):
            if row_index > 0 and self.y < BODY_BOTTOM + 35:
                self.new_page()
                draw_row(headers, 0)
            draw_row(row, row_index)
        self.y -= 12.0

    def render(self, blocks: list[tuple[str, object]]) -> None:
        for kind, value in blocks:
            if kind in ("title", "h2", "h3"):
                self.draw_heading(kind, str(value))
            elif kind == "paragraph":
                self.draw_paragraph(str(value))
            elif kind == "bullet":
                self.draw_paragraph(str(value), bullet=True)
            elif kind == "code":
                for line in value:  # type: ignore[union-attr]
                    self.draw_paragraph(line or " ", code=True)
            elif kind == "table":
                self.draw_table(value)  # type: ignore[arg-type]
            elif kind == "figure_pipeline":
                self.draw_pipeline(str(value))
            elif kind == "figure_cfg":
                self.draw_cfg(str(value))
        if self.commands:
            self.pages.append(self.commands)

    def pdf_bytes(self) -> bytes:
        count = len(self.pages)
        page_first = 3
        font_helv = page_first + count * 2
        font_helv_bold = font_helv + 1
        font_type0 = font_helv + 2
        font_cid = font_helv + 3
        cmap_id = font_helv + 4
        info_id = font_helv + 5

        objects: dict[int, bytes] = {}
        kids = " ".join(f"{page_first + 2 * i} 0 R" for i in range(count))
        objects[1] = b"<< /Type /Catalog /Pages 2 0 R /Lang (zh-CN) /ViewerPreferences << /DisplayDocTitle true >> >>"
        objects[2] = f"<< /Type /Pages /Kids [{kids}] /Count {count} >>".encode("ascii")

        for index, raw_commands in enumerate(self.pages):
            page_id = page_first + index * 2
            stream_id = page_id + 1
            commands = list(raw_commands)
            commands.extend([
                "q 0.70 0.74 0.78 RG 0.5 w 50 43 m 545.28 43 l S Q",
                f"BT /F1 8 Tf 1 0 0 1 50 27 Tm <{f'Page {index+1} / {count}'.encode('ascii').hex().upper()}> Tj ET",
            ])
            stream = ("\n".join(commands) + "\n").encode("ascii")
            objects[page_id] = (
                f"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 {PAGE_W:.2f} {PAGE_H:.2f}] "
                f"/Resources << /Font << /F1 {font_helv} 0 R /F1B {font_helv_bold} 0 R /F2 {font_type0} 0 R >> >> "
                f"/Contents {stream_id} 0 R >>"
            ).encode("ascii")
            objects[stream_id] = f"<< /Length {len(stream)} >>\nstream\n".encode("ascii") + stream + b"endstream"

        objects[font_helv] = b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>"
        objects[font_helv_bold] = b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>"
        objects[font_type0] = (
            f"<< /Type /Font /Subtype /Type0 /BaseFont /STSong-Light /Encoding /UniGB-UCS2-H "
            f"/DescendantFonts [{font_cid} 0 R] /ToUnicode {cmap_id} 0 R >>"
        ).encode("ascii")
        objects[font_cid] = (
            b"<< /Type /Font /Subtype /CIDFontType0 /BaseFont /STSong-Light "
            b"/CIDSystemInfo << /Registry (Adobe) /Ordering (GB1) /Supplement 4 >> /DW 1000 >>"
        )
        cmap = build_tounicode(self.used_codepoints)
        objects[cmap_id] = f"<< /Length {len(cmap)} >>\nstream\n".encode("ascii") + cmap + b"\nendstream"
        title_hex = pdf_hex("基于 Clang LLVM 的语言处理流程与 SysY 手写实现")
        objects[info_id] = f"<< /Title <FEFF{title_hex}> /Author (LIZZYGREAT) /Subject <FEFF{pdf_hex('编译原理实验报告')}> >>".encode("ascii")

        max_id = max(objects)
        output = bytearray(b"%PDF-1.7\n%\xE2\xE3\xCF\xD3\n")
        offsets = [0] * (max_id + 1)
        for obj_id in range(1, max_id + 1):
            offsets[obj_id] = len(output)
            output.extend(f"{obj_id} 0 obj\n".encode("ascii"))
            output.extend(objects[obj_id])
            output.extend(b"\nendobj\n")
        xref_offset = len(output)
        output.extend(f"xref\n0 {max_id+1}\n".encode("ascii"))
        output.extend(b"0000000000 65535 f \n")
        for obj_id in range(1, max_id + 1):
            output.extend(f"{offsets[obj_id]:010d} 00000 n \n".encode("ascii"))
        output.extend(
            f"trailer\n<< /Size {max_id+1} /Root 1 0 R /Info {info_id} 0 R >>\nstartxref\n{xref_offset}\n%%EOF\n".encode("ascii")
        )
        return bytes(output)


def validate_pdf(data: bytes, page_count: int) -> None:
    if not data.startswith(b"%PDF-1.7\n") or not data.rstrip().endswith(b"%%EOF"):
        raise ValueError("PDF header or EOF marker is missing")
    match = re.search(rb"startxref\s+(\d+)\s+%%EOF", data)
    if not match:
        raise ValueError("startxref is missing")
    xref_pos = int(match.group(1))
    if data[xref_pos : xref_pos + 5] != b"xref\n":
        raise ValueError("startxref does not point to xref table")
    if f"/Count {page_count}".encode("ascii") not in data:
        raise ValueError("page tree count does not match layout")
    for required in (b"/STSong-Light", b"/UniGB-UCS2-H", b"/ToUnicode"):
        if required not in data:
            raise ValueError(f"missing PDF font feature: {required.decode('ascii')}")
    lines = data[xref_pos:].splitlines()
    count = int(lines[1].split()[1])
    for obj_id in range(1, count):
        offset = int(lines[obj_id + 2][:10])
        if not data[offset:].startswith(f"{obj_id} 0 obj\n".encode("ascii")):
            raise ValueError(f"bad xref offset for object {obj_id}")


def main() -> int:
    if not SOURCE.is_file():
        raise FileNotFoundError(SOURCE)
    blocks = parse_markdown(SOURCE)
    layout = PDFLayout()
    layout.render(blocks)
    data = layout.pdf_bytes()
    validate_pdf(data, len(layout.pages))
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_bytes(data)
    digest = hashlib.sha256(data).hexdigest()
    print(f"Source: {SOURCE.relative_to(LAB_DIR)}")
    print(f"Output: {OUTPUT.relative_to(LAB_DIR)}")
    print(f"Pages: {len(layout.pages)}")
    print(f"Bytes: {len(data)}")
    print(f"SHA-256: {digest}")
    print("Structure, xref offsets, CJK font reference, and ToUnicode map: PASS")
    print("Generator: Python standard-library vector PDF writer.")
    print("Visual review: no PDF preview renderer is installed in this environment.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # provide an actionable log entry on build failure
        print(f"ERROR: {exc}", file=sys.stderr)
        raise
