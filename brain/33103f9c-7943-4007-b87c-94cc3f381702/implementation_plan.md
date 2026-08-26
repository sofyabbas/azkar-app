# Implementation Plan - Quran Page-Based Navigation & Bookmarks

This plan outlines the redesign of the Holy Quran screen to support a traditional 604-page Madinah Mushaf layout, continuous surah reading, page jumping, and bookmarking.

---

## Proposed Changes

### Component: Screens

#### [MODIFY] [quran_screen.dart](file:///c:/Users/Eng/Documents/azkar-app/lib/screens/quran_screen.dart)
- **QuranScreen (Surah Index)**:
  - Add a "Quick Action" card/button at the top of the Surah Index: **"الذهاب إلى علامة الحفظ 🔖"** (Go to Bookmark) if a bookmarked page exists.
  - Add a text input or button to quickly jump to any page number (1-604).
  - Modify the onTap of Surah cards to calculate the starting page of the Surah using `quran.getPageNumber(surahIndex, 1)` and open the page-based reader at that page index.

- **QuranReadingScreen (Page Reader)**:
  - Redesign the reading screen to use a horizontal `PageView.builder` ranging from page 1 to 604 (index 0 to 603).
  - Render each page `P` with:
    - **Header**: Surah name, page number, and Juz number.
    - **Verses**: Fetch verses in the page using `quran.getPageData(P)`. Iterate through surah portions on the page:
      - If `start == 1`, render the beautiful Surah Header ornament and Basmala (except Surah At-Tawbah and Surah Al-Fatihah).
      - Render the verses of that portion in a unified continuous `RichText` flow with Amiri font, custom sizes, and verse end symbols.
      - Strip Basmala from the first verse when a standalone Basmala is rendered.
    - **Footer**: A beautiful page number badge centered at the bottom of each page (e.g. `— الصفحة ٥0 —`).
  - **Bookmark Option**:
    - Add a bookmark icon (`IconButton`) in the AppBar.
    - Save/retrieve the bookmarked page index using `shared_preferences`.
    - Show visual confirmation (colored bookmark icon) when the current page matches the saved bookmark.
  - **Page Jump Option**:
    - Add an input or slider dialog allowing the user to jump directly to any page number (1-604).

---

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure there are no compilation errors or warnings.

### Manual Verification
1. Open the Quran screen from the home dashboard.
2. Click on Surah Al-Baqarah (starts on page 2). Verify page 2 is shown.
3. Scroll/swipe pages. Verify page 3, 4, 5 render consecutively.
4. Go to page 49 (where Surah Al-Baqarah ends and Surah Al-Imran starts). Verify both surahs are rendered on the same page, with a Surah Al-Imran Header and Basmala shown right below the end of Al-Baqarah!
5. Tap the bookmark button on page 50. Verify a toast/snack shows "تم حفظ الصفحة ٥٠ كعلامة مرجعية".
6. Return to the Surah Index. Verify the "الذهاب إلى علامة الحفظ (صفحة ٥٠)" button appears at the top.
7. Click the bookmark button. Verify it jumps directly to page 50.
