# 16 — ISO 24229 spelling systems on localized strings

**Status: done** · Source: basicdoc-models commit 0bc0c90

## Why
basicdoc-models identified localized strings as ISO 24229 spelling
systems — distinguishing the script-conversion system (transliteration,
transcription) from the language and script codes. Our LocalizedString
has language (ISO 639) and script (ISO 15924) but no ISO 24229 code.

## Changes
- `relaton/models/LocalizedString.lml`: add `+spellingSystem: Iso24229Code[0..*]`
- `relaton/models/Iso24229Code.lml`: new data_type for ISO 24229 codes
- RNC: `LocalizedStringAttributes` gains `attribute spelling-system { text }?`
