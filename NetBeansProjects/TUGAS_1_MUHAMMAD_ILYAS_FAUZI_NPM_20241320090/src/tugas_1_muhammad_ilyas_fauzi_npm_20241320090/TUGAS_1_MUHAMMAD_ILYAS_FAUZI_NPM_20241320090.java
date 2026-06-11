import javax.swing
import java.awt
package tugas_1_muhammad_ilyas_fauzi_npm_20241320090;
public class TUGAS_1_MUHAMMAD_ILYAS_FAUZI_NPM_20241320090 extends JFrame {
    public TUGAS_1_MUHAMMAD_ILYAS_FAUZI_NPM_20241320090 () ;
    public static void main(String[] args) {
        char[] p = {'a', 'b', 'c', 'd', 'e'};
        char[] x = upperCaseVersion(p);

        for (char c : x) {
            System.out.println(c);
        }
    }

    public static char[] upperCaseVersion(char[] a) {
        char[] result = new char[a.length]; // Buat salinan array
        for (int i = 0; i < a.length; i++) {
            result[i] = Character.toUpperCase(a[i]);
            public static void main(String[] args) {
        SwingUtilities.invokeLater(MyFrame::new);
            }
        }
        return result;
    }
}

