

import java.util.Comparator;

public class TennisStrokeComparator implements Comparator<TennisStroke> {
    
    @Override
    public int compare(TennisStroke stroke1, TennisStroke stroke2) {
        return Integer.compare(stroke1.getPriorityLevel(), stroke2.getPriorityLevel());
    }
}
