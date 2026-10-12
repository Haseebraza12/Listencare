# 003 — Reference visual system

Status: implemented; rendered previews reviewed at desktop and phone sizes.

The supplied 1504 × 1128 reference is the visual source. Match its purple atmospheric backdrop, white rounded phone surfaces, lavender cards, thin neutral borders, restrained black typography, lavender→pink→apricot accents, and delicate listening ribbons.

## Screen mapping
- Left: Your conversations. Weekly/Daily/Monthly tabs, connection card, real activity metrics, saved conversations. Adapt the productivity content to ListenCare's accessibility purpose.
- Center: Live captions. Back and settings buttons, ribbon ring with microphone and elapsed time, language/mode controls, readable captions, clear/pause/resume and save/copy controls.
- Right: Search. Gradient-bordered input, useful local filters, recent searches, shortcuts, and real saved results. The reference's AI suggestions become local discovery actions; no pretend AI.

## Layout
- At widths ≥1180, show all three panels. At 1504 the panels are 384 wide, have 60 gaps, 42 corner radii, and 832 height. Side panels begin 54 below the center panel.
- Below 1180, use a full-screen mobile surface with Conversations/Listen/Search navigation. Respect platform safe areas and large text. Inner content scrolls at short heights.
- Do not draw fake OS status bars. The operating system owns status and navigation chrome.
- Colors: ink #181610, muted #77737E, lavender #F5F0FE, border #E8E5EA, gradient #A879E9→#E6A9C5→#FFD68B.
- Logo: original rounded speech bubble with sound bars using the same gradient; canonical vector in assets/brand/listencare.svg, native vector painter in lib/widgets/brand_mark.dart.

Visual resemblance does not imply verified pixel equality across OS fonts, safe areas, and screens. Review generated previews and physical devices before accepting final visual fidelity.
