# Inter Font Files

Download the Inter font family from Google Fonts and place the following files in this directory:

## Required Files
- `Inter-Regular.ttf`
- `Inter-Medium.ttf`
- `Inter-SemiBold.ttf`
- `Inter-Bold.ttf`

## Download Instructions

1. Visit https://fonts.google.com/specimen/Inter
2. Click "Download family"
3. Extract the ZIP file
4. Copy the required `.ttf` files from the `static` folder to this directory

## Alternative: Direct Download

```bash
# From project root
curl -L "https://github.com/rsms/inter/releases/download/v4.0/Inter-4.0.zip" -o /tmp/inter.zip
unzip -j /tmp/inter.zip "Inter-4.0/extras/ttf/Inter-Regular.ttf" -d assets/fonts/
unzip -j /tmp/inter.zip "Inter-4.0/extras/ttf/Inter-Medium.ttf" -d assets/fonts/
unzip -j /tmp/inter.zip "Inter-4.0/extras/ttf/Inter-SemiBold.ttf" -d assets/fonts/
unzip -j /tmp/inter.zip "Inter-4.0/extras/ttf/Inter-Bold.ttf" -d assets/fonts/
rm /tmp/inter.zip
```

Once the font files are in place, the app will use them offline instead of fetching from Google Fonts.
