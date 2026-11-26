using UnityEngine;

// Unity port, milestone 1: a walkable street with the same Blender models as the Godot build.
public class Game : MonoBehaviour
{
    Transform player, cam;
    Vector2 stickStart, stick; bool dragging; int fid = -1;
    Font arFont;

    void Start()
    {
        RenderSettings.ambientLight = new Color(0.86f, 0.9f, 1f);
        RenderSettings.fog = true; RenderSettings.fogColor = new Color(0.85f, 0.9f, 1f); RenderSettings.fogDensity = 0.012f;
        var sunGo = new GameObject("sun"); var sun = sunGo.AddComponent<Light>(); sun.type = LightType.Directional;
        sun.color = new Color(1, 0.9f, 0.72f); sun.intensity = 1.0f; sunGo.transform.rotation = Quaternion.Euler(42, -55, 0);
        var cmGo = new GameObject("cam"); var c = cmGo.AddComponent<Camera>(); c.clearFlags = CameraClearFlags.SolidColor;
        c.backgroundColor = new Color(0.7f, 0.85f, 1f); c.farClipPlane = 140; cam = cmGo.transform; cmGo.tag = "MainCamera";

        Box(new Vector3(0, -0.05f, -60), new Vector3(300, 0.1f, 300), new Color(0.45f, 0.72f, 0.4f));
        Box(new Vector3(0, 0, -60), new Vector3(8, 0.12f, 130), new Color(0.58f, 0.57f, 0.62f));
        Box(new Vector3(-5.5f, 0.02f, -60), new Vector3(3, 0.14f, 130), new Color(0.9f, 0.84f, 0.7f));
        Box(new Vector3(5.5f, 0.02f, -60), new Vector3(3, 0.14f, 130), new Color(0.9f, 0.84f, 0.7f));

        for (int i = 0; i < 12; i++)
        {
            Place("bld_" + (i % 5), new Vector3(-10.5f, 0, -8 - i * 10), 90);
            Place("bld_" + ((i + 2) % 5), new Vector3(10.5f, 0, -8 - i * 10), -90);
        }
        Place("car", new Vector3(2.3f, 0, -30), 0); Place("bike", new Vector3(5.5f, 0, -20), 90);
        Place("bench", new Vector3(5.8f, 0, -12), -90); Place("fountain", new Vector3(14, 0, -8), 0);
        var p = Place("girl_long", new Vector3(0, 0, -2), 180); player = p ? p.transform : new GameObject("p").transform;
    }

    GameObject Place(string name, Vector3 pos, float yaw)
    {
        var prefab = Resources.Load<GameObject>("Models/" + name);
        if (prefab == null) { Debug.LogWarning("missing " + name); return null; }
        var g = Instantiate(prefab, pos, Quaternion.Euler(0, yaw, 0)); return g;
    }

    void Box(Vector3 pos, Vector3 size, Color col)
    {
        var g = GameObject.CreatePrimitive(PrimitiveType.Cube); g.transform.position = pos; g.transform.localScale = size;
        var m = new Material(Shader.Find("Standard")); m.color = col; g.GetComponent<Renderer>().material = m;
    }

    void Update()
    {
        Vector2 dir = Vector2.zero;
        if (Input.touchCount > 0)
        {
            var t = Input.GetTouch(0);
            if (t.phase == TouchPhase.Began) { stickStart = t.position; }
            Vector2 d = t.position - stickStart; dir = Vector2.ClampMagnitude(d / (Screen.height * 0.12f), 1f);
            if (t.phase == TouchPhase.Ended || t.phase == TouchPhase.Canceled) dir = Vector2.zero;
        }
        else dir = new Vector2(Input.GetAxis("Horizontal"), Input.GetAxis("Vertical"));
        stick = dir;
        if (player != null && dir.sqrMagnitude > 0.01f)
        {
            var mv = new Vector3(dir.x, 0, dir.y) * 3.2f * Time.deltaTime;
            var np = player.position + mv; np.x = Mathf.Clamp(np.x, -7f, 7f); np.z = Mathf.Clamp(np.z, -125f, 0f);
            player.position = np; player.rotation = Quaternion.Slerp(player.rotation, Quaternion.LookRotation(new Vector3(dir.x, 0, dir.y)), 12f * Time.deltaTime);
        }
        if (player != null)
        {
            var want = player.position + new Vector3(0, 3.2f, 5.2f);
            cam.position = Vector3.Lerp(cam.position, want, 6f * Time.deltaTime);
            cam.LookAt(player.position + Vector3.up * 1.2f);
        }
    }

    void OnGUI()
    {
        var s = new GUIStyle(GUI.skin.label) { fontSize = Screen.height / 20 };
        GUI.Label(new Rect(20, 10, Screen.width, Screen.height / 10), "Anime Life (Unity) - v0.1", s);
    }
}
