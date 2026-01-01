import re
from ..models import Student

def next_student_code(prefix: str = "S", width: int = 4) -> str:
    """Generate next student_code like S0001, S0002..."""
    max_n = 0
    rx = re.compile(rf"^{re.escape(prefix)}(\d+)$")
    for (code,) in Student.query.with_entities(Student.student_code).all():
        m = rx.match(code or "")
        if m:
            try:
                max_n = max(max_n, int(m.group(1)))
            except ValueError:
                pass
    return f"{prefix}{(max_n + 1):0{width}d}"
