# Mita App - Mitzy Character Assets

This package contains the official, finalized visual assets for the "Mitzy" companion character, specifically designed for the "Rate Us" dialog and the Winter Arc update.

## Package Structure
- `/characters`: Contains all individual Mitzy states in both high-resolution PNG and scalable SVG formats. (Source of Truth)
- `/previews`: Contains `asset_overview.png` for a quick visual reference.

## A) Guidelines for UI/UX Designers
1. **Asset Nature**: These files are flat vector graphics with a 2px stroke. They have been designed to sit neatly within a 100x100px circular container.
2. **Backgrounds**: The assets natively include a subtle 8% opacity mint-tinted circular background element. Do not layer an additional bounding box behind them.
3. **Usage Context**: These are intended for the "Rate Us" bottom sheet or dialog box, centered directly above the "Enjoying Mita?" headline. 
4. **Winter Arc**: The Winter Arc variants are seasonal. Ensure you swap the default `mitzy_rate` with the appropriate winter variant based on the active app season/campaign.

## B) Guidelines for Flutter / Full-Stack Developers
1. **Format Preference**: It is highly recommended to use the **SVG files** (`.svg`) via the `flutter_svg` package. SVGs prevent pixelation across varying screen densities (Retina/High-DPI).
2. **Implementation in Flutter**:
   - Add the files to your `assets/images/characters/` directory.
   - Update `pubspec.yaml`:
     ```yaml
     flutter:
       assets:
         - assets/images/characters/
     ```
   - Use in your widget tree:
     ```dart
     SvgPicture.asset(
       'assets/images/characters/mitzy_rate.svg',
       width: 100.0,
       height: 100.0,
     )
     ```
3. **Animation Context**: To implement the designed 3-second breathing loop, wrap the `SvgPicture` in a `SlideTransition` animated by an `AnimationController` looping a small vertical offset (e.g., `Offset(0, 0.03)`). No rotation is needed.

These are individual, production-ready files. Do not modify the source vectors.
