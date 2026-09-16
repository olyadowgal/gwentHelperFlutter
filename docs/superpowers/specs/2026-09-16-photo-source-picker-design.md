# Photo Source Picker — Design

## Problem

Tapping a player's avatar on the home screen only ever opens the gallery picker (`lib/features/home/view/home_view.dart:_pickPhoto`). There's no way to take a new photo with the camera. While reviewing this flow, two pre-existing bugs were also found that block photo picking from working reliably at all:

- **iOS**: `ios/Runner/Info.plist` declares neither `NSPhotoLibraryUsageDescription` nor `NSCameraUsageDescription`. iOS terminates the app when a picker call needs a missing usage-description string, so the current gallery-only flow is already broken on iOS.
- **Android**: `android/app/src/main/AndroidManifest.xml` declares no `android.permission.CAMERA`. Per Flutter's own `image_picker` issue tracker, without it `ImageSource.camera` fails silently with no error surfaced to the user.

## Goal

Tapping either player's avatar shows a choice between Camera and Gallery. Whichever is picked, the resulting image is cropped to a square (same crop step for both sources) and replaces the placeholder avatar. Cancelling the dialog, the picker, or the crop step — or denying a permission — is a silent no-op, matching the app's current behavior when a picker returns nothing.

## Design

**Permissions** (fixes the two bugs above, required regardless of the new UI):
- `Info.plist`: add `NSCameraUsageDescription` ("Used to take a player photo.") and `NSPhotoLibraryUsageDescription` ("Used to choose a player photo.").
- `AndroidManifest.xml`: add `<uses-permission android:name="android.permission.CAMERA"/>`.

**UI flow** (`lib/features/home/view/home_view.dart`):
- `PlayerInputWidget.onPhotoTap` now calls `_showPhotoSourceDialog(isPlayer1)` instead of going straight to `_pickPhoto`.
- `_showPhotoSourceDialog` shows a `showDialog<ImageSource>` `AlertDialog` with two options ("Camera", "Gallery") as `SimpleDialogOption`s (or `TextButton`s), each popping the dialog with the chosen `ImageSource`. No selection (dismissed/back button) resolves to `null`, and the flow stops there — no picker or crop dialog is shown.
- `_pickPhoto` gains an `ImageSource source` parameter (replacing the hardcoded `ImageSource.gallery`) and otherwise keeps its existing logic unchanged: pick → if null, return → crop (1:1, locked aspect ratio) → if null or `!mounted`, return → set the photo via the existing `HomeCubit` methods.
- No new strings need translation infrastructure; two labels ("Camera", "Gallery") and a dialog title ("Choose Photo") are added to `lib/features/home/resources/home_strings.dart`, following the existing `HomeStrings` pattern.

**Out of scope**: no new SideEffect, no permission-denied messaging (silent no-op per the approved design), no changes to `image_picker`/`image_cropper` versions or to the crop UI settings already in place.

## Testing

- Widget test: tapping an avatar shows the chooser dialog with both options visible.
- Manual verification on a real device/simulator for both platforms, since the picker and cropper are platform channels that don't run under `flutter test`.
