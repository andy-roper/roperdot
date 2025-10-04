"""
Example footer code for spell cheat sheets.

This footer extracts CSS custom properties (--character-name and --edition)
from the HTML document and uses them to generate a footer.

Usage:
    html2pdf --footer-code spell-sheet-footer.py ./spell-sheets ./pdfs
"""

def generate_footer(page):
    """
    Generate footer for D&D spell cheat sheets.
    
    Extracts character name and edition from CSS custom properties
    and returns a formatted footer template.
    
    Args:
        page: Playwright page object with HTML already loaded
        
    Returns:
        str: Footer template HTML, or None if custom properties not found
    """
    try:
        # Extract CSS custom properties
        character_name = page.evaluate("""
            () => getComputedStyle(document.documentElement)
                .getPropertyValue('--character-name')
                .trim()
                .replace(/['"]/g, '')
        """)
        
        edition = page.evaluate("""
            () => getComputedStyle(document.documentElement)
                .getPropertyValue('--edition')
                .trim()
                .replace(/['"]/g, '')
        """)
        
        # Only generate footer if both properties exist
        if character_name and edition:
            return f"""
                <div style="font-size: 9pt; font-family: Arial; text-align: right; width: 100%; padding-right: 13mm;">
                    {character_name}'s Spells for {edition} page <span class="pageNumber"></span>
                </div>
            """
    except Exception as e:
        # Silently fail - page might not have these properties
        pass
    
    return None