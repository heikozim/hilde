A {% set %} inside an {% if %} is refused: in Jinja2 the name is still there after the {% endif %} when the branch ran, and missing when it did not.
