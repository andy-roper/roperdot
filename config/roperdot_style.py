from pygments.style import Style
from pygments.token import Comment, Keyword, Name, String, Generic
import os


def env_color(name, default):
    val = os.environ.get(name)
    return '#' + val if val else default


GREEN     = env_color('COLOR_GREEN_RGB',     '#7a8431')
YELLOW    = env_color('COLOR_YELLOW_RGB',    '#d4804d')
BRCYAN    = env_color('COLOR_BRCYAN_RGB',    '#79b2a8')
BRBLUE    = env_color('COLOR_BRBLUE_RGB',    '#6f90b0')
BRGREEN   = env_color('COLOR_BRGREEN_RGB',   '#a6b255')
BRMAGENTA = env_color('COLOR_BRMAGENTA_RGB', '#a27fad')


class RoperdotStyle(Style):
    styles = {
        Comment:             GREEN,

        Keyword:             BRMAGENTA,
        Keyword.Declaration: BRBLUE,
        Keyword.Reserved:    BRBLUE,
        Keyword.Type:        BRGREEN,

        Name:                BRCYAN,
        Name.Attribute:      BRCYAN,
        Name.Builtin:        BRGREEN,
        Name.Tag:            BRBLUE,

        String:              YELLOW,
        String.Backtick:     YELLOW,
        String.Char:         YELLOW,

        Generic.Emph:        'italic',
        Generic.Strong:      'bold',
    }
