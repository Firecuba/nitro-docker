FROM node:lts-alpine as builder

ARG BRANCH=main
ARG COMMIT=33ff182

WORKDIR /build

RUN apk add --no-cache git python3 make g++
RUN git clone --branch ${BRANCH} --recurse-submodules https://github.com/Gurkengewuerz/nitro.git .
RUN git checkout $COMMIT

# Upstream (and its own upstream billsonnn/nitro-renderer) has never implemented the
# "mc"/"mcl"/"mcr" (misc hand accessories: gloves, scarves) or "pt"/"ptl"/"ptr" (worn
# pet companions) figure-string part types, even though official Habbo's own FigureData
# ships hundreds of items using them. Without this patch, those items silently render as
# nothing: FigureDataContainer's part-type whitelist drops any part code it doesn't
# recognize before it ever reaches the renderer. This adds recognition, geometry
# (mc/mcl/mcr placed on the torso/arms mirroring the existing cc/lc/rc jacket pattern;
# pt/ptl/ptr placed off to the side near the feet, since pet companions have no
# comparable existing part to mirror), and inclusion in the "figure"/"walk" active part
# sets so they're actually drawn.
COPY <<'EOF' /tmp/fix_mc_pt_support.py
import re

# --- 1) FigureDataContainer.ts: recognize the new part-type codes ---
path = "/build/libs/renderer/src/nitro/utils/FigureDataContainer.ts"
content = open(path).read()

old_consts = '  private static TROUSER_ACCESSORIES: string = "wa";\n  private static BLOCKED_FX_TYPES'
new_consts = (
    '  private static TROUSER_ACCESSORIES: string = "wa";\n'
    '  private static MISC_LEFT: string = "mcl";\n'
    '  private static MISC_RIGHT: string = "mcr";\n'
    '  private static MISC_CENTER: string = "mc";\n'
    '  private static PET_CENTER: string = "pt";\n'
    '  private static PET_LEFT: string = "ptl";\n'
    '  private static PET_RIGHT: string = "ptr";\n'
    '  private static BLOCKED_FX_TYPES'
)
assert content.count(old_consts) == 1, "FigureDataContainer consts anchor not found"
content = content.replace(old_consts, new_consts)

case_anchor = "      case FigureDataContainer.TROUSER_ACCESSORIES:\n"
new_cases = (
    case_anchor
    + "      case FigureDataContainer.MISC_LEFT:\n"
    + "      case FigureDataContainer.MISC_RIGHT:\n"
    + "      case FigureDataContainer.MISC_CENTER:\n"
    + "      case FigureDataContainer.PET_CENTER:\n"
    + "      case FigureDataContainer.PET_LEFT:\n"
    + "      case FigureDataContainer.PET_RIGHT:\n"
)
count = content.count(case_anchor)
assert count == 2, f"expected 2 switch-case anchors, found {count}"
content = content.replace(case_anchor, new_cases)
open(path, "w").write(content)
print("patched FigureDataContainer.ts")

# --- 2) HabboAvatarPartSets.ts: register part types + include in active sets ---
path = "/build/libs/renderer/src/nitro/avatar/data/HabboAvatarPartSets.ts"
content = open(path).read()

old = '''      {
        setType: "he",
      },
    ],
    activePartSets: ['''
new = '''      {
        setType: "he",
      },
      {
        setType: "mc",
      },
      {
        setType: "mcl",
        flippedSetType: "mcr",
      },
      {
        setType: "mcr",
        flippedSetType: "mcl",
      },
      {
        setType: "pt",
      },
      {
        setType: "ptl",
        flippedSetType: "ptr",
      },
      {
        setType: "ptr",
        flippedSetType: "ptl",
      },
    ],
    activePartSets: ['''
assert content.count(old) == 1, "partSet anchor not found"
content = content.replace(old, new)

old2 = '''          {
            setType: "he",
          },
        ],
      },
      {
        id: "head",'''
new2 = '''          {
            setType: "he",
          },
          {
            setType: "mc",
          },
          {
            setType: "mcl",
          },
          {
            setType: "mcr",
          },
          {
            setType: "pt",
          },
          {
            setType: "ptl",
          },
          {
            setType: "ptr",
          },
        ],
      },
      {
        id: "head",'''
assert content.count(old2) == 1, "figure activePartSet anchor not found"
content = content.replace(old2, new2)

old3 = '''          {
            setType: "sh",
          },
        ],
      },
      {
        id: "sit",'''
new3 = '''          {
            setType: "sh",
          },
          {
            setType: "mc",
          },
          {
            setType: "mcl",
          },
          {
            setType: "mcr",
          },
          {
            setType: "pt",
          },
          {
            setType: "ptl",
          },
          {
            setType: "ptr",
          },
        ],
      },
      {
        id: "sit",'''
assert content.count(old3) == 1, "walk activePartSet anchor not found"
content = content.replace(old3, new3)
open(path, "w").write(content)
print("patched HabboAvatarPartSets.ts")

# --- 3) HabboAvatarGeometry.ts: add mc/mcl/mcr next to cc/lc/rc, and a new
#         "petcompanion" bodyPart off to the side near the feet ---
path = "/build/libs/renderer/src/nitro/avatar/data/HabboAvatarGeometry.ts"
content = open(path).read()

def replace_all_or_die(content, old, new, expected):
    n = content.count(old)
    assert n == expected, f"expected {expected} occurrences, found {n}: {old[:60]!r}"
    return content.replace(old, new)

ca_block = '''              {
                id: "ca",
                x: 0,
                y: 0,
                z: 0,
                radius: 0.07,
                nx: 0,
                ny: 0,
                nz: -1,
                double: false,
              },'''
mc_block = '''
              {
                id: "mc",
                x: 0,
                y: 0,
                z: 0,
                radius: 0.075,
                nx: 0,
                ny: 0,
                nz: -1,
                double: false,
              },'''
content = replace_all_or_die(content, ca_block, ca_block + mc_block, 4)

lc_block = '''              {
                id: "lc",
                x: 0,
                y: 0,
                z: 0,
                radius: 0.025,
                nx: 0,
                ny: 0,
                nz: -1,
                double: false,
              },'''
mcl_block = '''
              {
                id: "mcl",
                x: 0,
                y: 0,
                z: 0,
                radius: 0.03,
                nx: 0,
                ny: 0,
                nz: -1,
                double: false,
              },'''
content = replace_all_or_die(content, lc_block, lc_block + mcl_block, 4)

rc_block = '''              {
                id: "rc",
                x: 0,
                y: 0,
                z: 0,
                radius: 0.025,
                nx: 0,
                ny: 0,
                nz: -1,
                double: false,
              },'''
mcr_block = '''
              {
                id: "mcr",
                x: 0,
                y: 0,
                z: 0,
                radius: 0.03,
                nx: 0,
                ny: 0,
                nz: -1,
                double: false,
              },'''
content = replace_all_or_die(content, rc_block, rc_block + mcr_block, 4)

# top-level bodyPart hierarchy: register the new "petcompanion" group once
old_hierarchy = '''              {
                id: "rightarm",
              },
            ],
          },'''
new_hierarchy = '''              {
                id: "rightarm",
              },
              {
                id: "petcompanion",
              },
            ],
          },'''
content = replace_all_or_die(content, old_hierarchy, new_hierarchy, 1)

# per-orientation geometry: add the petcompanion bodyPart right after each
# rightarm block (which now ends with the mcr item we just inserted above)
rc_close_with_mcr = '''              {
                id: "mcr",
                x: 0,
                y: 0,
                z: 0,
                radius: 0.03,
                nx: 0,
                ny: 0,
                nz: -1,
                double: false,
              },
            ],
          },'''
petcompanion_block = '''
          {
            id: "petcompanion",
            x: 1.4,
            y: 0,
            z: 0.3,
            radius: 0.3,
            items: [
              {
                id: "pt",
                x: 0,
                y: 0,
                z: 0,
                radius: 0.01,
                nx: 0,
                ny: 0,
                nz: -1,
                double: false,
              },
              {
                id: "ptl",
                x: 0,
                y: 0,
                z: 0,
                radius: 0.015,
                nx: 0,
                ny: 0,
                nz: -1,
                double: false,
              },
              {
                id: "ptr",
                x: 0,
                y: 0,
                z: 0,
                radius: 0.02,
                nx: 0,
                ny: 0,
                nz: -1,
                double: false,
              },
            ],
          },'''
content = replace_all_or_die(content, rc_close_with_mcr, rc_close_with_mcr + petcompanion_block, 4)

open(path, "w").write(content)
print("patched HabboAvatarGeometry.ts")
EOF
RUN python3 /tmp/fix_mc_pt_support.py && rm /tmp/fix_mc_pt_support.py

# The renderer-level patch above makes "mc"/"pt" render correctly, but the
# frontend app's Change-Your-Looks editor has its OWN separate copy of the
# figure-data whitelist (apps/frontend/src/api/avatar/FigureData.ts) plus its
# own per-tab category registration (TorsoModel.ts/LegModel.ts) and its own
# icon spritesheet CSS. Without this second patch, mc/pt items render fine on
# the avatar but never appear as a selectable tab/icon in the editor UI itself.
COPY <<'EOF' /tmp/fix_mc_pt_editor_ui.py
# --- 1) FigureData.ts (frontend app's own copy): recognize mc/pt ---
path = "/build/apps/frontend/src/api/avatar/FigureData.ts"
content = open(path).read()

old_const = '  public static TROUSER_ACCESSORIES: string = "wa";\n  public static SET_TYPES = ['
new_const = (
    '  public static TROUSER_ACCESSORIES: string = "wa";\n'
    '  public static MISC: string = "mc";\n'
    '  public static PET: string = "pt";\n'
    '  public static SET_TYPES = ['
)
assert content.count(old_const) == 1, "FigureData.ts consts anchor not found"
content = content.replace(old_const, new_const)

old_array_end = '    FigureData.TROUSERS,\n  ];'
new_array_end = '    FigureData.TROUSERS,\n    FigureData.MISC,\n    FigureData.PET,\n  ];'
assert content.count(old_array_end) == 1, "FigureData.ts SET_TYPES anchor not found"
content = content.replace(old_array_end, new_array_end)

case_anchor = "      case FigureData.TROUSER_ACCESSORIES:\n"
new_cases = case_anchor + "      case FigureData.MISC:\n      case FigureData.PET:\n"
count = content.count(case_anchor)
assert count == 2, f"expected 2 switch-case anchors in FigureData.ts, found {count}"
content = content.replace(case_anchor, new_cases)
open(path, "w").write(content)
print("patched FigureData.ts (frontend)")

# --- 2) TorsoModel.ts: expose MISC ("mc") as a 5th Torso sub-tab ---
path = "/build/apps/frontend/src/api/avatar/TorsoModel.ts"
content = open(path).read()
old = "    this.addCategory(FigureData.CHEST_ACCESSORIES);\n\n    this._isInitalized = true;"
new = "    this.addCategory(FigureData.CHEST_ACCESSORIES);\n    this.addCategory(FigureData.MISC);\n\n    this._isInitalized = true;"
assert content.count(old) == 1, "TorsoModel.ts anchor not found"
content = content.replace(old, new)
open(path, "w").write(content)
print("patched TorsoModel.ts")

# --- 3) LegModel.ts: expose PET ("pt") as a 4th Legs sub-tab ---
path = "/build/apps/frontend/src/api/avatar/LegModel.ts"
content = open(path).read()
old = "    this.addCategory(FigureData.TROUSER_ACCESSORIES);\n\n    this._isInitalized = true;"
new = "    this.addCategory(FigureData.TROUSER_ACCESSORIES);\n    this.addCategory(FigureData.PET);\n\n    this._isInitalized = true;"
assert content.count(old) == 1, "LegModel.ts anchor not found"
content = content.replace(old, new)
open(path, "w").write(content)
print("patched LegModel.ts")

# --- 4) AvatarEditorView.scss: give mc/pt a visible icon. There's no
#         dedicated glove/pet art, so this reuses existing sprite positions
#         that don't collide with any other icon already in the same tab
#         (wa's sprite for mc, since wa only otherwise appears on the Legs
#         tab; ca's sprite for pt, since ca only otherwise appears on Torso).
path = "/build/apps/frontend/src/components/avatar-editor/AvatarEditorView.scss"
content = open(path).read()
old = "    &.male-icon {"
new = '''    &.mc-icon {
        width: 36px;
        height: 18px;
        background-position: -226px -5px;

        &.selected, &:hover {
            width: 36px;
            height: 18px;
            background-position: -226px -33px;
        }
    }

    &.pt-icon {
        width: 25px;
        height: 25px;
        background-position: -226px -61px;

        &.selected, &:hover {
            width: 25px;
            height: 25px;
            background-position: -226px -96px;
        }
    }

    &.male-icon {'''
assert content.count(old) == 1, "AvatarEditorView.scss anchor not found"
content = content.replace(old, new)
open(path, "w").write(content)
print("patched AvatarEditorView.scss")
EOF
RUN python3 /tmp/fix_mc_pt_editor_ui.py && rm /tmp/fix_mc_pt_editor_ui.py

# Rank-gate: the 674 items added by tonight's official-parity cross-reference
# project (new heads/hairstyles/hats/pets/etc, never meant to be public)
# were showing up as freely selectable to every player, including rank 1
# members. Restrict them to staff (security level 6+, i.e. rank 6/7) using
# the client's existing hasSecurity() rank check. This deliberately does NOT
# include the real catalog-purchase items -- those still use the normal
# sellable+ownership check further down, so any rank can buy and wear them
# once purchased; only the brand-new non-commerce additions are staff-only.
COPY <<'EOF' /tmp/fix_rank_gate.py
path = "/build/apps/frontend/src/api/avatar/RankGatedSetIds.ts"
content = '''export const RANK_GATED_SET_IDS: Set<number> = new Set([
  6536, 6551, 6552, 6554, 6555, 6556, 6557, 6558, 6559, 6560, 6563, 6564, 6565, 6566, 6567, 6568, 6569, 6572, 6573, 6574, 6577, 6580, 10000, 10001, 10002, 10003, 10004, 10005, 10006, 10007, 10008, 10009, 10010, 10011, 10012, 10013, 10014, 10015, 10016, 10017, 10018, 10019, 10020, 10021, 10022, 10023, 10024, 10025, 10026, 10027, 10028, 10029, 10030, 10031, 10032, 10033, 10034, 10035, 10036, 10037, 10038, 10039, 10040, 10041, 10042, 10043, 10044, 10045, 10046, 10047, 10048, 10049, 10050, 10051, 10052, 10053, 10054, 10055, 10056, 10057, 10058, 10059, 10060, 10061, 10062, 10063, 10064, 10065, 10066, 10067, 10068, 10069, 10070, 10071, 10072, 10073, 10074, 10075, 10076, 10077, 10078, 10079, 10080, 10081, 10082, 10083, 10084, 10085, 10086, 10087, 10088, 10089, 10090, 10091, 10092, 10093, 10094, 10095, 10096, 10097, 10098, 10099, 10100, 10101, 10102, 10103, 10104, 10105, 10106, 10107, 10108, 10109, 10110, 10111, 10112, 10113, 10114, 10115, 10116, 10117, 10118, 10119, 10120, 10121, 10122, 10123, 10124, 10125, 10126, 10127, 10128, 10129, 10130, 10131, 10132, 10133, 10134, 10135, 10136, 10137, 10138, 10139, 10140, 10141, 10142, 10143, 10144, 10145, 10146, 10147, 10148, 10149, 10150, 10151, 10152, 10153, 10154, 10155, 10156, 10157, 10158, 10159, 10160, 10161, 10162, 10163, 10164, 10165, 10166, 10167, 10168, 10169, 10170, 10171, 10172, 10173, 10174, 10175, 10176, 10177, 10178, 10179, 10180, 10181, 10182, 10183, 10184, 10185, 10186, 10187, 10188, 10189, 10190, 10191, 10192, 10193, 10194, 10195, 10196, 10197, 10198, 10199, 10200, 10201, 10202, 10203, 10204, 10205, 10206, 10207, 10208, 10209, 10210, 10211, 10212, 10213, 10214, 10215, 10216, 10217, 10218, 10219, 10220, 10221, 10222, 10223, 10224, 10225, 10226, 10227, 10228, 10229, 10230, 10231, 10232, 10233, 10234, 10236, 10237, 10238, 10239, 10240, 10241, 10242, 10243, 10244, 10245, 10246, 10247, 10248, 10249, 10250, 10251, 10252, 10253, 10254, 10255, 10256, 10257, 10258, 10259, 10260, 10261, 10262, 10263, 10264, 10265, 10266, 10267, 10268, 10269, 10270, 10271, 10272, 10273, 10274, 10275, 10276, 10277, 10278, 10279, 10280, 10281, 10282, 10283, 10284, 10285, 10286, 10287, 10288, 10289, 10290, 10291, 10292, 10293, 10294, 10295, 10296, 10297, 10298, 10299, 10300, 10301, 10302, 10303, 10304, 10305, 10306, 10307, 10308, 10309, 10310, 10311, 10312, 10313, 10314, 10315, 10316, 10317, 10318, 10319, 10320, 10321, 10322, 10323, 10324, 10325, 10326, 10327, 10328, 10329, 10330, 10331, 10332, 10333, 10334, 10335, 10336, 10337, 10338, 10339, 10340, 10341, 10342, 10343, 10344, 10345, 10346, 10347, 10348, 10349, 10350, 10351, 10352, 10353, 10354, 10355, 10356, 10357, 10358, 10359, 10360, 10361, 10362, 10363, 10364, 10365, 10366, 10367, 10368, 10369, 10370, 10371, 10372, 10373, 10374, 10375, 10376, 10377, 10378, 10379, 10380, 10381, 10382, 10383, 10384, 10385, 10386, 10387, 10388, 10389, 10390, 10391, 10392, 10393, 10394, 10395, 10396, 10397, 10398, 10399, 10400, 10401, 10402, 10403, 10404, 10405, 10406, 10407, 10408, 10409, 10410, 10411, 10412, 10413, 10414, 10415, 10416, 10417, 10418, 10419, 10420, 10421, 10422, 10423, 10424, 10425, 10426, 10427, 10428, 10429, 10430, 10431, 10432, 10433, 10434, 10435, 10436, 10437, 10438, 10439, 10440, 10441, 10442, 10443, 10444, 10445, 10446, 10447, 10448, 10449, 10450, 10451, 10452, 10453, 10454, 10455, 10456, 10457, 10458, 10459, 10460, 10461, 10462, 10463, 10464, 10465, 10466, 10467, 10468, 10469, 10470, 10471, 10472, 10473, 10474, 10475, 10476, 10477, 10478, 10479, 10480, 10481, 10482, 10483, 10484, 10485, 10486, 10487, 10488, 10489, 10490, 10491, 10492, 10493, 10494, 10495, 10496, 10497, 10498, 10499, 10500, 10501, 10502, 10503, 10504, 10505, 10506, 10507, 10508, 10509, 10510, 10511, 10512, 10513, 10514, 10515, 10516, 10517, 10518, 10519, 10520, 10521, 10522, 10523, 10524, 10525, 10526, 10527, 10528, 10529, 10530, 10531, 10532, 10533, 10534, 10535, 10536, 10537, 10538, 10539, 10540, 10541, 10542, 10543, 10544, 10545, 10546, 10547, 10548, 10549, 10550, 10551, 10552, 10553, 10554, 10555, 10556, 10557, 10558, 10559, 10560, 10561, 10562, 10563, 10564, 10565, 10566, 10567, 10568, 10569, 10570, 10571, 10572, 10573, 10574, 10575, 10576, 10577, 10578, 10579, 10580, 10581, 10582, 10583, 10584, 10585, 10586, 10587, 10588, 10589, 10590, 10591, 10592, 10593, 10594, 10595, 10596, 10597, 10598, 10599, 10600, 10601, 10602, 10603, 10604, 10605, 10606, 10607, 10608, 10609, 10610, 10611, 10612, 10613, 10614, 10615, 10616, 10617, 10618, 10619, 10620, 10621, 10622, 10623, 10624, 10625, 10626, 10627, 10628, 10629, 10630, 10631, 10632, 10633, 10634, 10635, 10636, 10637, 10638, 10639, 10640, 10641, 10642, 10643, 10644, 10645, 10646, 10647, 10648, 10649, 10650, 10651, 10652, 10653, 10654, 10655, 10656, 10657, 10658, 10659, 10660, 10661, 10662, 10663, 10664, 10665, 10666, 10667, 10668, 10669, 10670, 10671, 10672, 10673, 10674, 10675, 10676, 10677, 10678, 10679, 10680, 10681, 10682, 10683, 10684, 10685, 10686, 10687, 10688, 10689, 10690, 10691, 10692, 10693, 10694, 10695, 10696, 10697, 10698, 10699, 10700, 10701, 10702
]);

export const RANK_GATED_MIN_SECURITY_LEVEL: number = 6;
'''
open(path, "w").write(content)
print("wrote RankGatedSetIds.ts")

path = "/build/apps/frontend/src/api/avatar/AvatarEditorUtilities.ts"
content = open(path).read()

old_import = 'import {GetAvatarPalette, GetAvatarRenderManager, GetAvatarSetType, GetClubMemberLevel, GetConfiguration} from "../nitro";'
new_import = (
    'import {GetAvatarPalette, GetAvatarRenderManager, GetAvatarSetType, GetClubMemberLevel, GetConfiguration, GetSessionDataManager} from "../nitro";\n'
    'import {RANK_GATED_MIN_SECURITY_LEVEL, RANK_GATED_SET_IDS} from "./RankGatedSetIds";'
)
assert content.count(old_import) == 1, "AvatarEditorUtilities.ts import anchor not found"
content = content.replace(old_import, new_import)

old_filter = '''        let isValid = true;

        if (partSet.isSellable) isValid = this.hasFigureSetId(partSet.id);

        if (isValid) partItems.push(new AvatarEditorGridPartItem(partSet, partColors, usesColors, isDisabled));'''
new_filter = '''        let isValid = true;

        if (RANK_GATED_SET_IDS.has(partSet.id)) {
          isValid = GetSessionDataManager().hasSecurity(RANK_GATED_MIN_SECURITY_LEVEL);
        } else if (partSet.isSellable) {
          isValid = this.hasFigureSetId(partSet.id);
        }

        if (isValid) partItems.push(new AvatarEditorGridPartItem(partSet, partColors, usesColors, isDisabled));'''
assert content.count(old_filter) == 1, "AvatarEditorUtilities.ts filter anchor not found"
content = content.replace(old_filter, new_filter)

open(path, "w").write(content)
print("patched AvatarEditorUtilities.ts")
EOF
RUN python3 /tmp/fix_rank_gate.py && rm /tmp/fix_rank_gate.py

# New feature: Recycler catalog page. The server (Arcturus) fully implements the
# furniture-recycling mechanic (prize tiers, RecycleEvent, message protocol) and the
# renderer library already has working composers/parsers/events for it, but this client
# never had an actual UI component wired up for the 'recycler' catalog layout -- it fell
# through to the generic default page view, which has no drag-and-drop item picker and no
# Recycle button. This adds that missing component and registers it in the layout router.
COPY <<'EOF' /build/apps/frontend/src/components/catalog/views/page/layout/CatalogLayoutRecyclerView.tsx
import {
  GetRecyclerStatusMessageComposer,
  RecycleItemsEntry,
  RecycleItemsMessageComposer,
  RecyclerFinishedMessageEvent,
  RecyclerStatusMessageEvent,
} from "@nitro/renderer";
import {FC, useEffect, useMemo, useState} from "react";

import {LocalizeText, NotificationAlertType, SendMessageComposer} from "../../../../../api";
import {AutoGrid, Button, Column, Flex, LayoutGridItem, Text} from "../../../../../common";
import {CatalogPurchaseFailureEvent} from "../../../../../events";
import {useInventoryFurni, useMessageEvent, useNotification, useUiEvent} from "../../../../../hooks";
import {CatalogLayoutProps} from "./CatalogLayout.types";

const RECYCLE_ITEM_COUNT = 8;

interface SelectedSlot {
  itemId: number;
  groupIndex: number;
}

export const CatalogLayoutRecyclerView: FC<CatalogLayoutProps> = props => {
  const [status, setStatus] = useState<number>(-1);
  const [selected, setSelected] = useState<SelectedSlot[]>([]);
  const {groupItems = [], activate = null, deactivate = null} = useInventoryFurni();
  const {simpleAlert = null} = useNotification();

  useMessageEvent<RecyclerStatusMessageEvent>(RecyclerStatusMessageEvent, event => {
    const parser = event.getParser();

    if (!parser) return;

    setStatus(parser.recyclerStatus);
  });

  useMessageEvent<RecyclerFinishedMessageEvent>(RecyclerFinishedMessageEvent, event => {
    const parser = event.getParser();

    if (!parser) return;

    setSelected([]);

    if (parser.recyclerFinishedStatus === RecyclerFinishedMessageEvent.FINISHED_OK) {
      simpleAlert(LocalizeText("catalog.recycler.success.desc"), NotificationAlertType.DEFAULT, null, null, LocalizeText("catalog.recycler.success.title"));
    } else {
      simpleAlert(LocalizeText("catalog.recycler.failed.desc"), NotificationAlertType.ALERT, null, null, LocalizeText("catalog.recycler.failed.title"));
    }
  });

  useUiEvent<CatalogPurchaseFailureEvent>(CatalogPurchaseFailureEvent.PURCHASE_FAILED, () => {
    simpleAlert(LocalizeText("catalog.recycler.failed.desc"), NotificationAlertType.ALERT, null, null, LocalizeText("catalog.recycler.failed.title"));
  });

  useEffect(() => {
    SendMessageComposer(new GetRecyclerStatusMessageComposer());
  }, []);

  useEffect(() => {
    if (!activate || !deactivate) return;

    const id = activate();

    return () => deactivate(id);
  }, [activate, deactivate]);

  const selectedIds = useMemo(() => selected.map(slot => slot.itemId), [selected]);

  // Not every furni type can be recycled -- the server flags this per-item
  // (already sent down with the normal inventory list), so only offer groups
  // that are actually eligible instead of letting the player pick anything
  // and find out it fails after the fact.
  const recyclableGroups = useMemo(
    () => groupItems.map((group, index) => ({group, index})).filter(({group}) => group.items.some(furniItem => furniItem.recyclable)),
    [groupItems]
  );

  const addItem = (groupIndex: number) => {
    if (selected.length >= RECYCLE_ITEM_COUNT) return;

    const group = groupItems[groupIndex];

    if (!group) return;

    const item = group.items.find(furniItem => furniItem.recyclable && !furniItem.locked && selectedIds.indexOf(furniItem.id) === -1);

    if (!item) return;

    setSelected(prevValue => [...prevValue, {itemId: item.id, groupIndex}]);
  };

  const removeSlot = (index: number) => {
    setSelected(prevValue => prevValue.filter((_, i) => i !== index));
  };

  const recycle = () => {
    if (selected.length !== RECYCLE_ITEM_COUNT) return;

    SendMessageComposer(new RecycleItemsMessageComposer(...selected.map(slot => new RecycleItemsEntry(slot.itemId))));
  };

  if (status === RecyclerStatusMessageEvent.SYSTEM_STATUS_DISABLED) {
    return (
      <Column center overflow="hidden" className="p-4">
        <Text center>{LocalizeText("catalog.recycler.disabled")}</Text>
      </Column>
    );
  }

  return (
    <Column overflow="hidden" gap={2}>
      <Text fontWeight="bold">{LocalizeText("catalog.recycler.select_items", ["count"], [RECYCLE_ITEM_COUNT.toString()])}</Text>
      <Flex gap={2} overflow="hidden">
        <Column size={7} overflow="hidden">
          <Text small>{LocalizeText("catalog.recycler.your_furni")}</Text>
          {recyclableGroups.length === 0 && <Text center>{LocalizeText("catalog.recycler.none_recyclable")}</Text>}
          <AutoGrid columnCount={4} overflow="auto">
            {recyclableGroups.map(({group, index}) => {
              const eligibleCount = group.items.filter(furniItem => furniItem.recyclable && !furniItem.locked).length;
              const remaining = eligibleCount - selected.filter(slot => slot.groupIndex === index).length;

              return (
                <LayoutGridItem
                  key={index}
                  className={remaining <= 0 ? "opacity-0-5" : ""}
                  itemImage={group.iconUrl}
                  itemCount={remaining}
                  onClick={() => remaining > 0 && addItem(index)}
                />
              );
            })}
          </AutoGrid>
        </Column>
        <Column size={5} overflow="hidden" justifyContent="between">
          <Column overflow="hidden" gap={1}>
            <Text small>{LocalizeText("catalog.recycler.selected", ["count", "max"], [selected.length.toString(), RECYCLE_ITEM_COUNT.toString()])}</Text>
            <AutoGrid columnCount={4}>
              {Array.from(Array(RECYCLE_ITEM_COUNT), (_, i) => {
                const slot = selected[i];

                if (!slot) return <LayoutGridItem key={i} />;

                const group = groupItems[slot.groupIndex];

                return <LayoutGridItem key={i} itemImage={group ? group.iconUrl : null} onClick={() => removeSlot(i)} />;
              })}
            </AutoGrid>
          </Column>
          <Button disabled={selected.length !== RECYCLE_ITEM_COUNT} onClick={recycle}>
            {LocalizeText("catalog.recycler.recycle_button")}
          </Button>
        </Column>
      </Flex>
    </Column>
  );
};
EOF

COPY <<'EOF' /tmp/fix_recycler_layout.py
path = "/build/apps/frontend/src/components/catalog/views/page/layout/GetCatalogLayout.tsx"
content = open(path).read()

old_import = 'import {CatalogLayoutPets3View} from "./CatalogLayoutPets3View";\nimport {CatalogLayoutRoomAdsView} from "./CatalogLayoutRoomAdsView";'
new_import = 'import {CatalogLayoutPets3View} from "./CatalogLayoutPets3View";\nimport {CatalogLayoutRecyclerView} from "./CatalogLayoutRecyclerView";\nimport {CatalogLayoutRoomAdsView} from "./CatalogLayoutRoomAdsView";'
assert content.count(old_import) == 1, "fix_recycler_layout: import anchor not found (upstream may have changed)"
content = content.replace(old_import, new_import)

old_case = '    case "soundmachine":\n      return <CatalogLayoutSoundMachineView {...layoutProps} />;'
new_case = '    case "soundmachine":\n      return <CatalogLayoutSoundMachineView {...layoutProps} />;\n    case "recycler":\n      return <CatalogLayoutRecyclerView {...layoutProps} />;'
assert content.count(old_case) == 1, "fix_recycler_layout: switch-case anchor not found (upstream may have changed)"
content = content.replace(old_case, new_case)

open(path, "w").write(content)
print("fix_recycler_layout: patched " + path)
EOF
RUN python3 /tmp/fix_recycler_layout.py && rm /tmp/fix_recycler_layout.py

# Upstream never finished wiring the Ecotron (Recycler reward box) double-click flow:
# RoomObjectLogicFactory already assigns FurnitureEcotronBoxLogic for the
# "furniture_ecotron_box" logic type, which correctly dispatches a
# RoomEngineTriggerWidgetEvent.REQUEST_ECOTRONBOX on double-click, and the server
# (OpenRecycleBoxEvent) replies with the exact same PresentItemOpenedComposer message
# used for regular gifts -- but the only frontend consumer of REQUEST_ECOTRONBOX
# (RoomWidgetsView.tsx) has that case as a commented-out no-op left over from the old
# Flash-era widget-messaging port, so double-clicking the box does nothing at all.
# Fix: make the existing gift-opening widget (useFurniturePresentWidget /
# FurnitureGiftOpeningView) also listen for REQUEST_ECOTRONBOX alongside REQUEST_PRESENT
# -- it already reuses the same underlying openGift()/PresentItemOpenedComposer plumbing,
# so no new UI is needed, just subscribing it to the second event type.
COPY <<'EOF' /tmp/fix_ecotron_box_open.py
path = "/build/apps/frontend/src/hooks/rooms/widgets/furniture/useFurniturePresentWidget.ts"
content = open(path).read()

old = "useRoomEngineEvent<RoomEngineTriggerWidgetEvent>(RoomEngineTriggerWidgetEvent.REQUEST_PRESENT, event => {"
new = "useRoomEngineEvent<RoomEngineTriggerWidgetEvent>([RoomEngineTriggerWidgetEvent.REQUEST_PRESENT, RoomEngineTriggerWidgetEvent.REQUEST_ECOTRONBOX], event => {"

assert content.count(old) == 1, "fix_ecotron_box_open: anchor not found (upstream may have changed)"
content = content.replace(old, new)

open(path, "w").write(content)
print("fix_ecotron_box_open: patched " + path)
EOF
RUN python3 /tmp/fix_ecotron_box_open.py && rm /tmp/fix_ecotron_box_open.py

# The Polls feature (room-entry surveys, `polls`/`polls_questions` tables, poll.id set
# on a room via the ":setpoll" command) is fully implemented server-side and even fully
# parsed client-side (PollHandler.ts, RoomSessionPollEvent, usePollWidget.ts dispatch the
# offer/content/error events correctly) -- but nothing ever listened for the
# RoomWidgetPollUpdateEvent it dispatches, so the poll silently vanished with no UI ever
# shown. Adds the missing widget (offer prompt -> question wizard -> thank-you) and wires
# it into RoomWidgetsView, and fixes a PollHandler.ts typo that clobbered the offer's
# headline field before it ever reached the widget.
#
# There's a second, deeper bug this also has to work around: the poll offer is pushed by
# the server unprompted the instant a player enters a room with an active poll, which (per
# live tracing) consistently arrives and gets dispatched by PollHandler.ts *before* React
# has mounted the room's widget tree and run the useEffect that subscribes to it -- so the
# very first offer of a room visit was always missed, event-bus fire-and-forget semantics
# with no replay for late subscribers. PollHandler.ts now stashes the last offer on the
# session manager; usePollWidgetView checks for one on mount as a catch-up path, in
# addition to the normal live subscription for anything that arrives after mount.
COPY <<'EOF' /build/apps/frontend/src/hooks/rooms/widgets/usePollWidgetView.ts
import {IPollQuestion} from "@nitro/renderer";
import {useEffect, useState} from "react";

import {GetRoomSessionManager, RoomWidgetPollUpdateEvent} from "../../../api";
import {useUiEvent} from "../../events";
import {usePollWidget} from "./usePollWidget";

const flattenQuestions = (questions: IPollQuestion[]): IPollQuestion[] => {
  const flat: IPollQuestion[] = [];

  (questions || []).forEach(question => {
    flat.push(question);

    if (question.children && question.children.length) flat.push(...question.children);
  });

  return flat;
};

const usePollWidgetViewState = () => {
  const {startPoll, rejectPoll, answerPoll} = usePollWidget();
  const [pollId, setPollId] = useState(-1);
  const [headline, setHeadline] = useState("");
  const [summary, setSummary] = useState("");
  const [showOffer, setShowOffer] = useState(false);
  const [showError, setShowError] = useState(false);
  const [showThanks, setShowThanks] = useState(false);
  const [endMessage, setEndMessage] = useState("");
  const [questions, setQuestions] = useState<IPollQuestion[]>([]);
  const [questionIndex, setQuestionIndex] = useState(0);
  const [selected, setSelected] = useState<string[]>([]);
  const [freeText, setFreeText] = useState("");

  useEffect(() => {
    const manager = GetRoomSessionManager() as any;
    const pending = manager?.lastPollOfferEvent;

    if (!pending) return;

    delete manager.lastPollOfferEvent;

    setPollId(pending.id);
    setHeadline(pending.headline);
    setSummary(pending.summary);
    setShowOffer(true);
  }, []);

  useUiEvent<RoomWidgetPollUpdateEvent>(RoomWidgetPollUpdateEvent.OFFER, event => {
    setPollId(event.id);
    setHeadline(event.headline);
    setSummary(event.summary);
    setShowError(false);
    setShowOffer(true);
  });

  useUiEvent<RoomWidgetPollUpdateEvent>(RoomWidgetPollUpdateEvent.ERROR, event => {
    setShowOffer(false);
    setQuestions([]);
    setShowThanks(false);
    setShowError(true);
  });

  useUiEvent<RoomWidgetPollUpdateEvent>(RoomWidgetPollUpdateEvent.CONTENT, event => {
    setPollId(event.id);
    setEndMessage(event.endMessage);
    setQuestions(flattenQuestions(event.questionArray));
    setQuestionIndex(0);
    setSelected([]);
    setFreeText("");
    setShowOffer(false);
    setShowThanks(false);
  });

  const accept = () => {
    setShowOffer(false);
    startPoll(pollId);
  };

  const decline = () => {
    setShowOffer(false);
    rejectPoll(pollId);
  };

  const currentQuestion = questions[questionIndex] || null;
  const hasChoices = !!currentQuestion?.questionChoices?.length;
  const isMultiSelect = currentQuestion?.questionType === 1;

  const toggleChoice = (value: string) => {
    setSelected(prev => {
      if (isMultiSelect) return prev.includes(value) ? prev.filter(v => v !== value) : [...prev, value];

      return [value];
    });
  };

  const canSubmit = hasChoices ? selected.length > 0 : freeText.trim().length > 0;

  const submitAnswer = () => {
    if (!currentQuestion) return;

    const answerValue = hasChoices ? selected.join(";") : freeText;

    answerPoll(pollId, currentQuestion.questionId, [answerValue]);

    setSelected([]);
    setFreeText("");

    if (questionIndex + 1 < questions.length) {
      setQuestionIndex(questionIndex + 1);
    } else {
      setQuestions([]);
      setShowThanks(true);
    }
  };

  const closeThanks = () => setShowThanks(false);
  const closeError = () => setShowError(false);

  return {
    showOffer,
    showError,
    showThanks,
    headline,
    summary,
    endMessage,
    currentQuestion,
    hasChoices,
    isMultiSelect,
    questionNumber: questionIndex + 1,
    totalQuestions: questions.length,
    selected,
    freeText,
    setFreeText,
    toggleChoice,
    canSubmit,
    submitAnswer,
    accept,
    decline,
    closeThanks,
    closeError,
  };
};

export const usePollWidgetView = usePollWidgetViewState;
EOF

COPY <<'EOF' /build/apps/frontend/src/components/room/widgets/poll/PollWidgetView.tsx
import {FC} from "react";

import {LocalizeText} from "../../../../api";
import {Button, Column, Flex, NitroCardContentView, NitroCardHeaderView, NitroCardView, Text} from "../../../../common";
import {usePollWidgetView} from "../../../../hooks";

export const PollWidgetView: FC<{}> = props => {
  const {
    showOffer = false,
    showError = false,
    showThanks = false,
    headline = "",
    summary = "",
    endMessage = "",
    currentQuestion = null,
    hasChoices = false,
    isMultiSelect = false,
    questionNumber = 0,
    totalQuestions = 0,
    selected = [],
    freeText = "",
    setFreeText = null,
    toggleChoice = null,
    canSubmit = false,
    submitAnswer = null,
    accept = null,
    decline = null,
    closeThanks = null,
    closeError = null,
  } = usePollWidgetView();

  if (showError) {
    return (
      <NitroCardView className="nitro-widget-poll no-resize" theme="primary-slim">
        <NitroCardHeaderView headerText={LocalizeText("poll.error.title")} onCloseClick={() => closeError()} />
        <NitroCardContentView>
          <Text>{LocalizeText("poll.error.description")}</Text>
        </NitroCardContentView>
      </NitroCardView>
    );
  }

  if (showOffer) {
    return (
      <NitroCardView className="nitro-widget-poll no-resize" theme="primary-slim">
        <NitroCardHeaderView headerText={LocalizeText("poll.offer.title")} onCloseClick={() => decline()} />
        <NitroCardContentView>
          <Column gap={2}>
            <Text bold>{summary}</Text>
            {headline.length > 0 && <Text>{headline}</Text>}
            <Flex justifyContent="end" gap={1}>
              <Button variant="secondary" onClick={() => decline()}>
                {LocalizeText("poll.offer.decline")}
              </Button>
              <Button variant="success" onClick={() => accept()}>
                {LocalizeText("poll.offer.accept")}
              </Button>
            </Flex>
          </Column>
        </NitroCardContentView>
      </NitroCardView>
    );
  }

  if (showThanks) {
    return (
      <NitroCardView className="nitro-widget-poll no-resize" theme="primary-slim">
        <NitroCardHeaderView headerText={LocalizeText("poll.thanks.title")} onCloseClick={() => closeThanks()} />
        <NitroCardContentView>
          <Column gap={2}>
            <Text>{endMessage}</Text>
            <Flex justifyContent="end">
              <Button variant="success" onClick={() => closeThanks()}>
                {LocalizeText("generic.ok")}
              </Button>
            </Flex>
          </Column>
        </NitroCardContentView>
      </NitroCardView>
    );
  }

  if (currentQuestion) {
    return (
      <NitroCardView className="nitro-widget-poll no-resize" theme="primary-slim">
        <NitroCardHeaderView headerText={LocalizeText("poll.question.title", ["number", "total"], [questionNumber.toString(), totalQuestions.toString()])} />
        <NitroCardContentView>
          <Column gap={2}>
            <Text bold>{currentQuestion.questionText}</Text>
            {hasChoices && (
              <Column gap={1}>
                {currentQuestion.questionChoices.map(choice => (
                  <Flex key={choice.choiceText} alignItems="center" gap={1}>
                    <input
                      className="form-check-input"
                      type={isMultiSelect ? "checkbox" : "radio"}
                      name="poll-choice"
                      checked={selected.includes(choice.choiceText)}
                      onChange={() => toggleChoice(choice.choiceText)}
                    />
                    <Text pointer onClick={() => toggleChoice(choice.choiceText)}>
                      {choice.value}
                    </Text>
                  </Flex>
                ))}
              </Column>
            )}
            {!hasChoices && (
              <textarea className="form-control form-control-sm" value={freeText} onChange={event => setFreeText(event.target.value)} />
            )}
            <Flex justifyContent="end" gap={1}>
              <Button variant="secondary" onClick={() => decline()}>
                {LocalizeText("poll.question.cancel")}
              </Button>
              <Button variant="success" disabled={!canSubmit} onClick={() => submitAnswer()}>
                {questionNumber >= totalQuestions ? LocalizeText("poll.question.finish") : LocalizeText("poll.question.next")}
              </Button>
            </Flex>
          </Column>
        </NitroCardContentView>
      </NitroCardView>
    );
  }

  return null;
};
EOF

COPY <<'EOF' /tmp/fix_poll_widget_wireup.py
import re

# 1. Export the new hook
path = "/build/apps/frontend/src/hooks/rooms/widgets/index.ts"
content = open(path).read()
old = 'export * from "./usePollWidget";\n'
new = 'export * from "./usePollWidget";\nexport * from "./usePollWidgetView";\n'
assert content.count(old) == 1, "fix_poll_widget_wireup: hooks index anchor not found"
open(path, "w").write(content.replace(old, new))

# 2. Mount the widget in RoomWidgetsView
path = "/build/apps/frontend/src/components/room/widgets/RoomWidgetsView.tsx"
content = open(path).read()
old_import = 'import {PetPackageWidgetView} from "./pet-package/PetPackageWidgetView";\nimport {RoomFilterWordsWidgetView} from "./room-filter-words/RoomFilterWordsWidgetView";'
new_import = 'import {PetPackageWidgetView} from "./pet-package/PetPackageWidgetView";\nimport {PollWidgetView} from "./poll/PollWidgetView";\nimport {RoomFilterWordsWidgetView} from "./room-filter-words/RoomFilterWordsWidgetView";'
assert content.count(old_import) == 1, "fix_poll_widget_wireup: RoomWidgetsView import anchor not found"
content = content.replace(old_import, new_import)
old_render = "      <WordQuizWidgetView />\n      <FriendRequestWidgetView />"
new_render = "      <WordQuizWidgetView />\n      <PollWidgetView />\n      <FriendRequestWidgetView />"
assert content.count(old_render) == 1, "fix_poll_widget_wireup: RoomWidgetsView render anchor not found"
content = content.replace(old_render, new_render)
open(path, "w").write(content)

# 3. Fix PollHandler.ts clobbering the offer's headline field with summary twice, and
#    stash the last offer on the session manager so a late-mounting widget can catch up.
path = "/build/libs/renderer/src/nitro/session/handler/PollHandler.ts"
content = open(path).read()
old = """pollEvent.summary = parser.headline;
    pollEvent.summary = parser.summary;

    this.listener.events.dispatchEvent(pollEvent);
  }"""
new = """pollEvent.headline = parser.headline;
    pollEvent.summary = parser.summary;

    (this.listener as any).lastPollOfferEvent = pollEvent;
    this.listener.events.dispatchEvent(pollEvent);
  }"""
assert content.count(old) == 1, "fix_poll_widget_wireup: PollHandler.ts anchor not found"
content = content.replace(old, new)
open(path, "w").write(content)

print("fix_poll_widget_wireup: patched all files")
EOF
RUN python3 /tmp/fix_poll_widget_wireup.py && rm /tmp/fix_poll_widget_wireup.py

# New feature: a rank-7-only "set custom video by URL" control on the Video TV widget,
# bypassing the normal admin-curated youtube_playlists system entirely (paired server-side
# patch: arcturus/patches/hotfix_youtube_custom_video.patch adds SetYoutubeCustomVideoEvent
# and a canSetCustomVideo flag on the existing playlists response). The real security
# boundary is the server-side rank check in that new event handler; this client-side flag
# only controls whether the input is shown at all, so a non-rank-7 account never even
# sees a control that would just get rejected.
COPY <<'EOF' /build/libs/renderer/src/nitro/communication/messages/outgoing/room/furniture/youtube/SetYoutubeCustomVideoMessageComposer.ts
import {IMessageComposer} from "../../../../../../../api";

export class SetYoutubeCustomVideoMessageComposer
  implements IMessageComposer<ConstructorParameters<typeof SetYoutubeCustomVideoMessageComposer>>
{
  private _data: ConstructorParameters<typeof SetYoutubeCustomVideoMessageComposer>;

  constructor(k: number, _arg_2: string) {
    this._data = [k, _arg_2];
  }

  public getMessageArray() {
    return this._data;
  }

  public dispose(): void {
    return;
  }
}
EOF

COPY <<'EOF' /tmp/fix_youtube_custom_video_client.py
import re

# 1. New outgoing header (same custom number as the server side).
path = "/build/libs/renderer/src/nitro/communication/messages/outgoing/OutgoingHeader.ts"
content = open(path).read()
old = "  public static SET_YOUTUBE_DISPLAY_PLAYLIST = 2069;\n"
new = "  public static SET_YOUTUBE_DISPLAY_PLAYLIST = 2069;\n  public static SET_YOUTUBE_CUSTOM_VIDEO = 32001;\n"
assert content.count(old) == 1, "fix_youtube_custom_video_client: OutgoingHeader.ts anchor not found"
open(path, "w").write(content.replace(old, new))

# 2. Export the new composer from the youtube outgoing barrel.
path = "/build/libs/renderer/src/nitro/communication/messages/outgoing/room/furniture/youtube/index.ts"
content = open(path).read()
old = 'export * from "./SetYoutubeDisplayPlaylistMessageComposer";\n'
new = 'export * from "./SetYoutubeCustomVideoMessageComposer";\nexport * from "./SetYoutubeDisplayPlaylistMessageComposer";\n'
assert content.count(old) == 1, "fix_youtube_custom_video_client: youtube outgoing index.ts anchor not found"
open(path, "w").write(content.replace(old, new))

# 3. Register the composer with NitroMessages.
path = "/build/libs/renderer/src/nitro/communication/NitroMessages.ts"
content = open(path).read()
old_import = "  SetYoutubeDisplayPlaylistMessageComposer,\n"
new_import = "  SetYoutubeCustomVideoMessageComposer,\n  SetYoutubeDisplayPlaylistMessageComposer,\n"
assert content.count(old_import) == 1, "fix_youtube_custom_video_client: NitroMessages.ts import anchor not found"
content = content.replace(old_import, new_import)
old_reg = "    this._composers.set(OutgoingHeader.SET_YOUTUBE_DISPLAY_PLAYLIST, SetYoutubeDisplayPlaylistMessageComposer);\n"
new_reg = "    this._composers.set(OutgoingHeader.SET_YOUTUBE_DISPLAY_PLAYLIST, SetYoutubeDisplayPlaylistMessageComposer);\n    this._composers.set(OutgoingHeader.SET_YOUTUBE_CUSTOM_VIDEO, SetYoutubeCustomVideoMessageComposer);\n"
assert content.count(old_reg) == 1, "fix_youtube_custom_video_client: NitroMessages.ts registration anchor not found"
content = content.replace(old_reg, new_reg)
open(path, "w").write(content)

# 4. Parser: read the new canSetCustomVideo boolean appended to the wire message.
path = "/build/libs/renderer/src/nitro/communication/messages/parser/room/furniture/youtube/YoutubeDisplayPlaylistsMessageParser.ts"
content = open(path).read()
old = '''export class YoutubeDisplayPlaylistsMessageParser implements IMessageParser {
  private _furniId: number;
  private _playlists: YoutubeDisplayPlaylist[];
  private _selectedPlaylistId: string;

  flush(): boolean {
    this._furniId = -1;
    this._playlists = null;
    this._selectedPlaylistId = null;
    return true;
  }

  parse(wrapper: IMessageDataWrapper): boolean {
    this._furniId = wrapper.readInt();
    const count = wrapper.readInt();
    this._playlists = [];
    for (let i = 0; i < count; i++) {
      this._playlists.push(new YoutubeDisplayPlaylist(wrapper.readString(), wrapper.readString(), wrapper.readString()));
    }
    this._selectedPlaylistId = wrapper.readString();
    return true;
  }

  public get furniId(): number {
    return this._furniId;
  }

  public get playlists(): YoutubeDisplayPlaylist[] {
    return this._playlists;
  }

  public get selectedPlaylistId(): string {
    return this._selectedPlaylistId;
  }
}'''
new = '''export class YoutubeDisplayPlaylistsMessageParser implements IMessageParser {
  private _furniId: number;
  private _playlists: YoutubeDisplayPlaylist[];
  private _selectedPlaylistId: string;
  private _canSetCustomVideo: boolean;

  flush(): boolean {
    this._furniId = -1;
    this._playlists = null;
    this._selectedPlaylistId = null;
    this._canSetCustomVideo = false;
    return true;
  }

  parse(wrapper: IMessageDataWrapper): boolean {
    this._furniId = wrapper.readInt();
    const count = wrapper.readInt();
    this._playlists = [];
    for (let i = 0; i < count; i++) {
      this._playlists.push(new YoutubeDisplayPlaylist(wrapper.readString(), wrapper.readString(), wrapper.readString()));
    }
    this._selectedPlaylistId = wrapper.readString();
    this._canSetCustomVideo = wrapper.readBoolean();
    return true;
  }

  public get furniId(): number {
    return this._furniId;
  }

  public get playlists(): YoutubeDisplayPlaylist[] {
    return this._playlists;
  }

  public get selectedPlaylistId(): string {
    return this._selectedPlaylistId;
  }

  public get canSetCustomVideo(): boolean {
    return this._canSetCustomVideo;
  }
}'''
assert content.count(old) == 1, "fix_youtube_custom_video_client: YoutubeDisplayPlaylistsMessageParser.ts anchor not found"
open(path, "w").write(content.replace(old, new))

# 5. Hook: expose canSetCustomVideo + a setCustomVideo() action that sends the new packet.
path = "/build/apps/frontend/src/hooks/rooms/widgets/furniture/useFurnitureYoutubeWidget.ts"
content = open(path).read()

old_import = '''import {
  ControlYoutubeDisplayPlaybackMessageComposer,
  GetYoutubeDisplayStatusMessageComposer,
  RoomEngineTriggerWidgetEvent,
  RoomId,
  SecurityLevel,
  SetYoutubeDisplayPlaylistMessageComposer,
  YoutubeControlVideoMessageEvent,
  YoutubeDisplayPlaylist,
  YoutubeDisplayPlaylistsEvent,
  YoutubeDisplayVideoMessageEvent,
} from "@nitro/renderer";'''
new_import = '''import {
  ControlYoutubeDisplayPlaybackMessageComposer,
  GetYoutubeDisplayStatusMessageComposer,
  RoomEngineTriggerWidgetEvent,
  RoomId,
  SecurityLevel,
  SetYoutubeCustomVideoMessageComposer,
  SetYoutubeDisplayPlaylistMessageComposer,
  YoutubeControlVideoMessageEvent,
  YoutubeDisplayPlaylist,
  YoutubeDisplayPlaylistsEvent,
  YoutubeDisplayVideoMessageEvent,
} from "@nitro/renderer";'''
assert content.count(old_import) == 1, "fix_youtube_custom_video_client: useFurnitureYoutubeWidget.ts import anchor not found"
content = content.replace(old_import, new_import)

old_state = "  const [playlists, setPlaylists] = useState<YoutubeDisplayPlaylist[]>(null);\n  const [hasControl, setHasControl] = useState(false);"
new_state = "  const [playlists, setPlaylists] = useState<YoutubeDisplayPlaylist[]>(null);\n  const [hasControl, setHasControl] = useState(false);\n  const [canSetCustomVideo, setCanSetCustomVideo] = useState(false);"
assert content.count(old_state) == 1, "fix_youtube_custom_video_client: useFurnitureYoutubeWidget.ts state anchor not found"
content = content.replace(old_state, new_state)

old_close = "    setPlaylists(null);\n    setHasControl(false);\n  };"
new_close = "    setPlaylists(null);\n    setHasControl(false);\n    setCanSetCustomVideo(false);\n  };"
assert content.count(old_close) == 1, "fix_youtube_custom_video_client: useFurnitureYoutubeWidget.ts onClose anchor not found"
content = content.replace(old_close, new_close)

old_select = '''  const selectVideo = (video: string) => {'''
new_select = '''  const setCustomVideo = (urlOrVideoId: string) => SendMessageComposer(new SetYoutubeCustomVideoMessageComposer(objectId, urlOrVideoId));

  const selectVideo = (video: string) => {'''
assert content.count(old_select) == 1, "fix_youtube_custom_video_client: useFurnitureYoutubeWidget.ts selectVideo anchor not found"
content = content.replace(old_select, new_select)

old_playlists_event = '''    setPlaylists(parser.playlists);
    setSelectedVideo(parser.selectedPlaylistId);
    setVideoId(null);
    setCurrentVideoState(-1);
    setVideoEnd(null);
    setVideoStart(null);
  });'''
new_playlists_event = '''    setPlaylists(parser.playlists);
    setSelectedVideo(parser.selectedPlaylistId);
    setCanSetCustomVideo(parser.canSetCustomVideo);
    setVideoId(null);
    setCurrentVideoState(-1);
    setVideoEnd(null);
    setVideoStart(null);
  });'''
assert content.count(old_playlists_event) == 1, "fix_youtube_custom_video_client: useFurnitureYoutubeWidget.ts playlists-event anchor not found"
content = content.replace(old_playlists_event, new_playlists_event)

old_return = "  return {objectId, videoId, videoStart, videoEnd, currentVideoState, selectedVideo, playlists, onClose, previous, next, pause, play, selectVideo};"
new_return = "  return {objectId, videoId, videoStart, videoEnd, currentVideoState, selectedVideo, playlists, canSetCustomVideo, onClose, previous, next, pause, play, selectVideo, setCustomVideo};"
assert content.count(old_return) == 1, "fix_youtube_custom_video_client: useFurnitureYoutubeWidget.ts return anchor not found"
content = content.replace(old_return, new_return)

open(path, "w").write(content)

# 6. Widget UI: a "Set custom video" input + button, only rendered when the server told
#    us this account is allowed to use it.
path = "/build/apps/frontend/src/components/room/widgets/furniture/FurnitureYoutubeDisplayView.tsx"
content = open(path).read()

old_import = '''import {LocalizeText, YoutubeVideoPlaybackStateEnum} from "../../../../api";
import {AutoGrid, AutoGridProps, LayoutGridItem, NitroCardContentView, NitroCardHeaderView, NitroCardView} from "../../../../common";
import {useFurnitureYoutubeWidget} from "../../../../hooks";'''
new_import = '''import {useState} from "react";

import {LocalizeText, YoutubeVideoPlaybackStateEnum} from "../../../../api";
import {AutoGrid, AutoGridProps, Button, LayoutGridItem, NitroCardContentView, NitroCardHeaderView, NitroCardView} from "../../../../common";
import {useFurnitureYoutubeWidget} from "../../../../hooks";'''
assert content.count(old_import) == 1, "fix_youtube_custom_video_client: FurnitureYoutubeDisplayView.tsx import anchor not found"
content = content.replace(old_import, new_import)

old_destructure = '''    playlists = [],
    onClose = null,
    previous = null,
    next = null,
    pause = null,
    play = null,
    selectVideo = null,
  } = useFurnitureYoutubeWidget();'''
new_destructure = '''    playlists = [],
    canSetCustomVideo = false,
    onClose = null,
    previous = null,
    next = null,
    pause = null,
    play = null,
    selectVideo = null,
    setCustomVideo = null,
  } = useFurnitureYoutubeWidget();

  const [customVideoInput, setCustomVideoInput] = useState("");'''
assert content.count(old_destructure) == 1, "fix_youtube_custom_video_client: FurnitureYoutubeDisplayView.tsx destructure anchor not found"
content = content.replace(old_destructure, new_destructure)

old_playlist_grid = '''            <AutoGrid columnCount={1} columnMinWidth={80} columnMinHeight={100} className="mb-1" overflow="auto">
              {playlists &&
                playlists.map((entry, index) => {
                  return (
                    <LayoutGridItem key={index} onClick={event => selectVideo(entry.video)} itemActive={entry.video === selectedVideo}>
                      <b>{entry.title}</b>
                    </LayoutGridItem>
                  );
                })}
            </AutoGrid>
          </div>'''
new_playlist_grid = '''            <AutoGrid columnCount={1} columnMinWidth={80} columnMinHeight={100} className="mb-1" overflow="auto">
              {playlists &&
                playlists.map((entry, index) => {
                  return (
                    <LayoutGridItem key={index} onClick={event => selectVideo(entry.video)} itemActive={entry.video === selectedVideo}>
                      <b>{entry.title}</b>
                    </LayoutGridItem>
                  );
                })}
            </AutoGrid>
            {canSetCustomVideo && (
              <div className="custom-video-input d-flex flex-column mt-1">
                <input
                  type="text"
                  className="form-control form-control-sm mb-1"
                  placeholder={LocalizeText("widget.furni.video_viewer.custom_video.placeholder")}
                  value={customVideoInput}
                  onChange={event => setCustomVideoInput(event.target.value)}
                />
                <Button
                  variant="success"
                  disabled={customVideoInput.trim().length === 0}
                  onClick={() => {
                    setCustomVideo(customVideoInput.trim());
                    setCustomVideoInput("");
                  }}
                >
                  {LocalizeText("widget.furni.video_viewer.custom_video.play")}
                </Button>
              </div>
            )}
          </div>'''
assert content.count(old_playlist_grid) == 1, "fix_youtube_custom_video_client: FurnitureYoutubeDisplayView.tsx playlist-grid anchor not found"
content = content.replace(old_playlist_grid, new_playlist_grid)

open(path, "w").write(content)

print("fix_youtube_custom_video_client: patched all files")
EOF
RUN python3 /tmp/fix_youtube_custom_video_client.py && rm /tmp/fix_youtube_custom_video_client.py

# New feature: rank-7 can point a Video TV at a video file they uploaded themselves
# (self-hosted, own-content-only -- see the upload panel's required acknowledgment
# checkbox), instead of a YouTube video. Paired server-side patch:
# arcturus/patches/hotfix_youtube_custom_video.patch's SetCustomUploadedVideoEvent /
# CustomVideoDisplayMessageComposer / InteractionYoutubeTV.customVideoUrl.
COPY <<'EOF' /build/libs/renderer/src/nitro/communication/messages/outgoing/room/furniture/youtube/SetCustomUploadedVideoMessageComposer.ts
import {IMessageComposer} from "../../../../../../../api";

export class SetCustomUploadedVideoMessageComposer
  implements IMessageComposer<ConstructorParameters<typeof SetCustomUploadedVideoMessageComposer>>
{
  private _data: ConstructorParameters<typeof SetCustomUploadedVideoMessageComposer>;

  constructor(k: number, _arg_2: string) {
    this._data = [k, _arg_2];
  }

  public getMessageArray() {
    return this._data;
  }

  public dispose(): void {
    return;
  }
}
EOF

COPY <<'EOF' /build/libs/renderer/src/nitro/communication/messages/parser/room/furniture/youtube/CustomVideoDisplayMessageParser.ts
import {IMessageDataWrapper, IMessageParser} from "../../../../../../../api";

export class CustomVideoDisplayMessageParser implements IMessageParser {
  private _furniId: number;
  private _url: string;

  flush(): boolean {
    return true;
  }

  parse(wrapper: IMessageDataWrapper): boolean {
    this._furniId = wrapper.readInt();
    this._url = wrapper.readString();
    return true;
  }

  public get furniId(): number {
    return this._furniId;
  }

  public get url(): string {
    return this._url;
  }
}
EOF

COPY <<'EOF' /build/libs/renderer/src/nitro/communication/messages/incoming/room/furniture/youtube/CustomVideoDisplayMessageEvent.ts
import {IMessageEvent} from "../../../../../../../api";
import {MessageEvent} from "../../../../../../../events";
import {CustomVideoDisplayMessageParser} from "../../../../parser";

export class CustomVideoDisplayMessageEvent extends MessageEvent implements IMessageEvent {
  constructor(callBack: Function) {
    super(callBack, CustomVideoDisplayMessageParser);
  }

  public getParser(): CustomVideoDisplayMessageParser {
    return this.parser as CustomVideoDisplayMessageParser;
  }
}
EOF

COPY <<'EOF' /tmp/fix_custom_video_upload_client_wire.py
import re

# 1. New outgoing header.
path = "/build/libs/renderer/src/nitro/communication/messages/outgoing/OutgoingHeader.ts"
content = open(path).read()
old = "  public static SET_YOUTUBE_CUSTOM_VIDEO = 32001;\n"
new = "  public static SET_YOUTUBE_CUSTOM_VIDEO = 32001;\n  public static SET_CUSTOM_UPLOADED_VIDEO = 32002;\n"
assert content.count(old) == 1, "fix_custom_video_upload_client_wire: OutgoingHeader.ts anchor not found"
open(path, "w").write(content.replace(old, new))

# 2. New incoming header.
path = "/build/libs/renderer/src/nitro/communication/messages/incoming/IncomingHeader.ts"
content = open(path).read()
old = "  public static YOUTUBE_DISPLAY_VIDEO = 1411;\n"
new = "  public static YOUTUBE_DISPLAY_VIDEO = 1411;\n  public static CUSTOM_VIDEO_DISPLAY = 32003;\n"
assert content.count(old) == 1, "fix_custom_video_upload_client_wire: IncomingHeader.ts anchor not found"
open(path, "w").write(content.replace(old, new))

# 3. Export the new outgoing composer from the youtube outgoing barrel.
path = "/build/libs/renderer/src/nitro/communication/messages/outgoing/room/furniture/youtube/index.ts"
content = open(path).read()
old = 'export * from "./SetYoutubeCustomVideoMessageComposer";\n'
new = 'export * from "./SetCustomUploadedVideoMessageComposer";\nexport * from "./SetYoutubeCustomVideoMessageComposer";\n'
assert content.count(old) == 1, "fix_custom_video_upload_client_wire: outgoing youtube index.ts anchor not found"
open(path, "w").write(content.replace(old, new))

# 4. Export the new incoming event from the youtube incoming barrel.
path = "/build/libs/renderer/src/nitro/communication/messages/incoming/room/furniture/youtube/index.ts"
content = open(path).read()
old = 'export * from "./YoutubeDisplayVideoMessageEvent";\n'
assert content.count(old) == 1, "fix_custom_video_upload_client_wire: incoming youtube index.ts anchor not found"
new = old + 'export * from "./CustomVideoDisplayMessageEvent";\n'
open(path, "w").write(content.replace(old, new))

# 5. Export the new parser from the youtube parser barrel.
path = "/build/libs/renderer/src/nitro/communication/messages/parser/room/furniture/youtube/index.ts"
content = open(path).read()
old = 'export * from "./YoutubeDisplayVideoMessageParser";\n'
assert content.count(old) == 1, "fix_custom_video_upload_client_wire: parser youtube index.ts anchor not found"
new = old + 'export * from "./CustomVideoDisplayMessageParser";\n'
open(path, "w").write(content.replace(old, new))

# 6. Register both with NitroMessages.
path = "/build/libs/renderer/src/nitro/communication/NitroMessages.ts"
content = open(path).read()

old_import1 = "  SetYoutubeCustomVideoMessageComposer,\n"
new_import1 = "  SetCustomUploadedVideoMessageComposer,\n  SetYoutubeCustomVideoMessageComposer,\n"
assert content.count(old_import1) == 1, "fix_custom_video_upload_client_wire: NitroMessages.ts composer import anchor not found"
content = content.replace(old_import1, new_import1)

old_import2 = "  YoutubeDisplayVideoMessageEvent,\n"
assert content.count(old_import2) == 1, "fix_custom_video_upload_client_wire: NitroMessages.ts event import anchor not found"
new_import2 = old_import2 + "  CustomVideoDisplayMessageEvent,\n"
content = content.replace(old_import2, new_import2)

old_reg1 = "    this._composers.set(OutgoingHeader.SET_YOUTUBE_CUSTOM_VIDEO, SetYoutubeCustomVideoMessageComposer);\n"
new_reg1 = old_reg1 + "    this._composers.set(OutgoingHeader.SET_CUSTOM_UPLOADED_VIDEO, SetCustomUploadedVideoMessageComposer);\n"
assert content.count(old_reg1) == 1, "fix_custom_video_upload_client_wire: NitroMessages.ts composer registration anchor not found"
content = content.replace(old_reg1, new_reg1)

old_reg2 = "    this._events.set(IncomingHeader.YOUTUBE_DISPLAY_VIDEO, YoutubeDisplayVideoMessageEvent);\n"
assert content.count(old_reg2) == 1, "fix_custom_video_upload_client_wire: NitroMessages.ts event registration anchor not found"
new_reg2 = old_reg2 + "    this._events.set(IncomingHeader.CUSTOM_VIDEO_DISPLAY, CustomVideoDisplayMessageEvent);\n"
content = content.replace(old_reg2, new_reg2)

open(path, "w").write(content)
print("fix_custom_video_upload_client_wire: patched all files")
EOF
RUN python3 /tmp/fix_custom_video_upload_client_wire.py && rm /tmp/fix_custom_video_upload_client_wire.py

# Wire protocol for the picture gallery: a new outgoing header (mirrors the server's
# Incoming.setCustomPictureEvent = 32004), a new field on the existing playlists-status
# parser (server appends it after canSetCustomVideo, see YoutubeDisplayPlaylistsComposer
# in hotfix_youtube_media_features.patch), and a new outgoing composer.
COPY <<'EOF' /build/libs/renderer/src/nitro/communication/messages/outgoing/room/furniture/youtube/SetCustomPictureMessageComposer.ts
import {IMessageComposer} from "../../../../../../../api";

export class SetCustomPictureMessageComposer implements IMessageComposer<ConstructorParameters<typeof SetCustomPictureMessageComposer>> {
  private _data: ConstructorParameters<typeof SetCustomPictureMessageComposer>;

  constructor(k: number, _arg_2: string) {
    this._data = [k, _arg_2];
  }

  public getMessageArray() {
    return this._data;
  }

  public dispose(): void {
    return;
  }
}
EOF

COPY <<'EOF' /tmp/fix_custom_picture_client_wire.py
path = "/build/libs/renderer/src/nitro/communication/messages/outgoing/OutgoingHeader.ts"
content = open(path).read()
old = "  public static SET_CUSTOM_UPLOADED_VIDEO = 32002;\n"
new = old + "  public static SET_CUSTOM_PICTURE = 32004;\n"
assert content.count(old) == 1, "fix_custom_picture_client_wire: OutgoingHeader.ts anchor not found"
open(path, "w").write(content.replace(old, new))

path = "/build/libs/renderer/src/nitro/communication/messages/parser/room/furniture/youtube/YoutubeDisplayPlaylistsMessageParser.ts"
content = open(path).read()

old_field = "  private _canSetCustomVideo: boolean;\n"
new_field = old_field + "  private _customPictureUrl: string;\n"
assert content.count(old_field) == 1, "fix_custom_picture_client_wire: parser field anchor not found"
content = content.replace(old_field, new_field)

old_flush = "    this._canSetCustomVideo = false;\n    return true;"
new_flush = "    this._canSetCustomVideo = false;\n    this._customPictureUrl = null;\n    return true;"
assert content.count(old_flush) == 1, "fix_custom_picture_client_wire: parser flush anchor not found"
content = content.replace(old_flush, new_flush)

old_parse = "    this._canSetCustomVideo = wrapper.readBoolean();\n    return true;"
new_parse = "    this._canSetCustomVideo = wrapper.readBoolean();\n    this._customPictureUrl = wrapper.readString();\n    return true;"
assert content.count(old_parse) == 1, "fix_custom_picture_client_wire: parser parse anchor not found"
content = content.replace(old_parse, new_parse)

old_getter = '''  public get canSetCustomVideo(): boolean {
    return this._canSetCustomVideo;
  }
}'''
new_getter = '''  public get canSetCustomVideo(): boolean {
    return this._canSetCustomVideo;
  }

  public get customPictureUrl(): string {
    return this._customPictureUrl;
  }
}'''
assert content.count(old_getter) == 1, "fix_custom_picture_client_wire: parser getter anchor not found"
content = content.replace(old_getter, new_getter)

open(path, "w").write(content)

path = "/build/libs/renderer/src/nitro/communication/messages/outgoing/room/furniture/youtube/index.ts"
content = open(path).read()
old = 'export * from "./SetCustomUploadedVideoMessageComposer";\n'
assert content.count(old) == 1, "fix_custom_picture_client_wire: outgoing youtube index.ts anchor not found"
open(path, "w").write(content.replace(old, old + 'export * from "./SetCustomPictureMessageComposer";\n'))

path = "/build/libs/renderer/src/nitro/communication/NitroMessages.ts"
content = open(path).read()

old_import = "  SetCustomUploadedVideoMessageComposer,\n"
assert content.count(old_import) == 1, "fix_custom_picture_client_wire: NitroMessages.ts import anchor not found"
content = content.replace(old_import, old_import + "  SetCustomPictureMessageComposer,\n")

old_reg = "    this._composers.set(OutgoingHeader.SET_CUSTOM_UPLOADED_VIDEO, SetCustomUploadedVideoMessageComposer);\n"
assert content.count(old_reg) == 1, "fix_custom_picture_client_wire: NitroMessages.ts registration anchor not found"
content = content.replace(old_reg, old_reg + "    this._composers.set(OutgoingHeader.SET_CUSTOM_PICTURE, SetCustomPictureMessageComposer);\n")

open(path, "w").write(content)
print("fix_custom_picture_client_wire: patched all files")
EOF
RUN python3 /tmp/fix_custom_picture_client_wire.py && rm /tmp/fix_custom_picture_client_wire.py

# Wire protocol for the overlay gallery: a new outgoing header (mirrors the server's
# Incoming.setOverlayEvent = 32005), a new trailing field on the playlists-status
# parser (server appends it after customPictureUrl, see YoutubeDisplayPlaylistsComposer
# in hotfix_youtube_media_features.patch), and a new outgoing composer.
COPY <<'EOF' /build/libs/renderer/src/nitro/communication/messages/outgoing/room/furniture/youtube/SetOverlayMessageComposer.ts
import {IMessageComposer} from "../../../../../../../api";

export class SetOverlayMessageComposer implements IMessageComposer<ConstructorParameters<typeof SetOverlayMessageComposer>> {
  private _data: ConstructorParameters<typeof SetOverlayMessageComposer>;

  constructor(k: number, _arg_2: string) {
    this._data = [k, _arg_2];
  }

  public getMessageArray() {
    return this._data;
  }

  public dispose(): void {
    return;
  }
}
EOF

COPY <<'EOF' /tmp/fix_overlay_client_wire.py
path = "/build/libs/renderer/src/nitro/communication/messages/outgoing/OutgoingHeader.ts"
content = open(path).read()
old = "  public static SET_CUSTOM_PICTURE = 32004;\n"
new = old + "  public static SET_OVERLAY = 32005;\n"
assert content.count(old) == 1, "fix_overlay_client_wire: OutgoingHeader.ts anchor not found"
open(path, "w").write(content.replace(old, new))

path = "/build/libs/renderer/src/nitro/communication/messages/parser/room/furniture/youtube/YoutubeDisplayPlaylistsMessageParser.ts"
content = open(path).read()

old_field = "  private _customPictureUrl: string;\n"
new_field = old_field + "  private _overlayUrl: string;\n"
assert content.count(old_field) == 1, "fix_overlay_client_wire: parser field anchor not found"
content = content.replace(old_field, new_field)

old_flush = "    this._customPictureUrl = null;\n    return true;"
new_flush = "    this._customPictureUrl = null;\n    this._overlayUrl = null;\n    return true;"
assert content.count(old_flush) == 1, "fix_overlay_client_wire: parser flush anchor not found"
content = content.replace(old_flush, new_flush)

old_parse = "    this._customPictureUrl = wrapper.readString();\n    return true;"
new_parse = "    this._customPictureUrl = wrapper.readString();\n    this._overlayUrl = wrapper.readString();\n    return true;"
assert content.count(old_parse) == 1, "fix_overlay_client_wire: parser parse anchor not found"
content = content.replace(old_parse, new_parse)

old_getter = '''  public get customPictureUrl(): string {
    return this._customPictureUrl;
  }
}'''
new_getter = '''  public get customPictureUrl(): string {
    return this._customPictureUrl;
  }

  public get overlayUrl(): string {
    return this._overlayUrl;
  }
}'''
assert content.count(old_getter) == 1, "fix_overlay_client_wire: parser getter anchor not found"
content = content.replace(old_getter, new_getter)

open(path, "w").write(content)

path = "/build/libs/renderer/src/nitro/communication/messages/outgoing/room/furniture/youtube/index.ts"
content = open(path).read()
old = 'export * from "./SetCustomPictureMessageComposer";\n'
assert content.count(old) == 1, "fix_overlay_client_wire: outgoing youtube index.ts anchor not found"
open(path, "w").write(content.replace(old, old + 'export * from "./SetOverlayMessageComposer";\n'))

path = "/build/libs/renderer/src/nitro/communication/NitroMessages.ts"
content = open(path).read()

old_import = "  SetCustomPictureMessageComposer,\n"
assert content.count(old_import) == 1, "fix_overlay_client_wire: NitroMessages.ts import anchor not found"
content = content.replace(old_import, old_import + "  SetOverlayMessageComposer,\n")

old_reg = "    this._composers.set(OutgoingHeader.SET_CUSTOM_PICTURE, SetCustomPictureMessageComposer);\n"
assert content.count(old_reg) == 1, "fix_overlay_client_wire: NitroMessages.ts registration anchor not found"
content = content.replace(old_reg, old_reg + "    this._composers.set(OutgoingHeader.SET_OVERLAY, SetOverlayMessageComposer);\n")

open(path, "w").write(content)
print("fix_overlay_client_wire: patched all files")
EOF
RUN python3 /tmp/fix_overlay_client_wire.py && rm /tmp/fix_overlay_client_wire.py

# Full-file rewrite of the hook: supersedes fix_custom_video_upload_hook (folded in
# below) and adds picture-gallery state (customPictureUrl) alongside the existing
# YouTube/uploaded-video state. Setting any one of the three (YouTube video, uploaded
# video, picture) is treated as clearing the other two client-side, matching the
# server's mutually-exclusive InteractionYoutubeTV fields.
COPY <<'EOF' /build/apps/frontend/src/hooks/rooms/widgets/furniture/useFurnitureYoutubeWidget.ts
import {
  ControlYoutubeDisplayPlaybackMessageComposer,
  CustomVideoDisplayMessageEvent,
  GetYoutubeDisplayStatusMessageComposer,
  RoomEngineTriggerWidgetEvent,
  RoomId,
  SecurityLevel,
  SetCustomPictureMessageComposer,
  SetCustomUploadedVideoMessageComposer,
  SetOverlayMessageComposer,
  SetYoutubeCustomVideoMessageComposer,
  SetYoutubeDisplayPlaylistMessageComposer,
  YoutubeControlVideoMessageEvent,
  YoutubeDisplayPlaylist,
  YoutubeDisplayPlaylistsEvent,
  YoutubeDisplayVideoMessageEvent,
} from "@nitro/renderer";
import {useState} from "react";

import {GetRoomEngine, GetSessionDataManager, IsOwnerOfFurniture, SendMessageComposer, YoutubeVideoPlaybackStateEnum} from "../../../../api";
import {useMessageEvent, useRoomEngineEvent} from "../../../events";
import {useFurniRemovedEvent} from "../../engine";

const CONTROL_COMMAND_PREVIOUS_VIDEO = 0;
const CONTROL_COMMAND_NEXT_VIDEO = 1;
const CONTROL_COMMAND_PAUSE_VIDEO = 2;
const CONTROL_COMMAND_CONTINUE_VIDEO = 3;

const useFurnitureYoutubeWidgetState = () => {
  const [objectId, setObjectId] = useState(-1);
  const [category, setCategory] = useState(-1);
  const [videoId, setVideoId] = useState<string>(null);
  const [videoStart, setVideoStart] = useState<number>(null);
  const [videoEnd, setVideoEnd] = useState<number>(null);
  const [currentVideoState, setCurrentVideoState] = useState(-1);
  const [selectedVideo, setSelectedVideo] = useState<string>(null);
  const [playlists, setPlaylists] = useState<YoutubeDisplayPlaylist[]>(null);
  const [hasControl, setHasControl] = useState(false);
  const [canSetCustomVideo, setCanSetCustomVideo] = useState(false);
  const [customVideoUrl, setCustomVideoUrl] = useState<string>(null);
  const [customPictureUrl, setCustomPictureUrl] = useState<string>(null);
  const [overlayUrl, setOverlayUrl] = useState<string>(null);

  const onClose = () => {
    setObjectId(-1);
    setCategory(-1);
    setVideoId(null);
    setVideoStart(null);
    setVideoEnd(null);
    setCurrentVideoState(-1);
    setSelectedVideo(null);
    setPlaylists(null);
    setHasControl(false);
    setCanSetCustomVideo(false);
    setCustomVideoUrl(null);
    setCustomPictureUrl(null);
    setOverlayUrl(null);
  };

  const previous = () => SendMessageComposer(new ControlYoutubeDisplayPlaybackMessageComposer(objectId, CONTROL_COMMAND_PREVIOUS_VIDEO));

  const next = () => SendMessageComposer(new ControlYoutubeDisplayPlaybackMessageComposer(objectId, CONTROL_COMMAND_NEXT_VIDEO));

  const hasPlayableVideo = () => (videoId && videoId.length > 0) || (customVideoUrl && customVideoUrl.length > 0);

  const pause = () =>
    hasControl && hasPlayableVideo() && SendMessageComposer(new ControlYoutubeDisplayPlaybackMessageComposer(objectId, CONTROL_COMMAND_PAUSE_VIDEO));

  const play = () =>
    hasControl && hasPlayableVideo() && SendMessageComposer(new ControlYoutubeDisplayPlaybackMessageComposer(objectId, CONTROL_COMMAND_CONTINUE_VIDEO));

  const setCustomUploadedVideo = (url: string) => {
    setCustomPictureUrl(null);
    SendMessageComposer(new SetCustomUploadedVideoMessageComposer(objectId, url));
  };

  const setCustomVideo = (urlOrVideoId: string) => {
    setCustomPictureUrl(null);
    SendMessageComposer(new SetYoutubeCustomVideoMessageComposer(objectId, urlOrVideoId));
  };

  const setCustomPicture = (url: string) => {
    setCustomPictureUrl(url);
    setVideoId(null);
    setCustomVideoUrl(null);
    setCurrentVideoState(-1);
    SendMessageComposer(new SetCustomPictureMessageComposer(objectId, url));
  };

  // Independent of video/picture state -- an overlay sits on top of whatever's
  // already showing, so setting or clearing (url === "") it never touches the
  // other fields. Kept even while a new video/picture is selected underneath it.
  const setOverlay = (url: string) => {
    setOverlayUrl(url && url.length > 0 ? url : null);
    SendMessageComposer(new SetOverlayMessageComposer(objectId, url));
  };

  const selectVideo = (video: string) => {
    if (selectedVideo === video) {
      setSelectedVideo(null);
      SendMessageComposer(new SetYoutubeDisplayPlaylistMessageComposer(objectId, ""));

      return;
    }

    setSelectedVideo(video);
    SendMessageComposer(new SetYoutubeDisplayPlaylistMessageComposer(objectId, video));
  };

  useRoomEngineEvent<RoomEngineTriggerWidgetEvent>(RoomEngineTriggerWidgetEvent.REQUEST_YOUTUBE, event => {
    if (RoomId.isRoomPreviewerId(event.roomId)) return;

    const roomObject = GetRoomEngine().getRoomObject(event.roomId, event.objectId, event.category);

    if (!roomObject) return;

    setObjectId(event.objectId);
    setCategory(event.category);
    setHasControl(GetSessionDataManager().hasSecurity(SecurityLevel.EMPLOYEE) || IsOwnerOfFurniture(roomObject));

    SendMessageComposer(new GetYoutubeDisplayStatusMessageComposer(event.objectId));
  });

  useMessageEvent<YoutubeDisplayVideoMessageEvent>(YoutubeDisplayVideoMessageEvent, event => {
    const parser = event.getParser();

    if (objectId === -1 || objectId !== parser.furniId) return;

    setVideoId(parser.videoId);
    setVideoStart(parser.startAtSeconds);
    setVideoEnd(parser.endAtSeconds);
    setCurrentVideoState(parser.state);
    setCustomVideoUrl(null);
    setCustomPictureUrl(null);
  });

  useMessageEvent<CustomVideoDisplayMessageEvent>(CustomVideoDisplayMessageEvent, event => {
    const parser = event.getParser();

    if (objectId === -1 || objectId !== parser.furniId) return;

    setCustomVideoUrl(parser.url);
    setCustomPictureUrl(null);
    setVideoId(null);
    setVideoStart(null);
    setVideoEnd(null);
    setCurrentVideoState(YoutubeVideoPlaybackStateEnum.PLAYING);
  });

  useMessageEvent<YoutubeDisplayPlaylistsEvent>(YoutubeDisplayPlaylistsEvent, event => {
    const parser = event.getParser();

    if (objectId === -1 || objectId !== parser.furniId) return;

    setPlaylists(parser.playlists);
    setSelectedVideo(parser.selectedPlaylistId);
    setCanSetCustomVideo(parser.canSetCustomVideo);
    setCustomPictureUrl(parser.customPictureUrl && parser.customPictureUrl.length > 0 ? parser.customPictureUrl : null);
    setOverlayUrl(parser.overlayUrl && parser.overlayUrl.length > 0 ? parser.overlayUrl : null);
    setVideoId(null);
    setCustomVideoUrl(null);
    setCurrentVideoState(-1);
    setVideoEnd(null);
    setVideoStart(null);
  });

  useMessageEvent<YoutubeControlVideoMessageEvent>(YoutubeControlVideoMessageEvent, event => {
    const parser = event.getParser();

    if (objectId === -1 || objectId !== parser.furniId) return;

    switch (parser.commandId) {
      case 1:
        setCurrentVideoState(YoutubeVideoPlaybackStateEnum.PLAYING);
        break;
      case 2:
        setCurrentVideoState(YoutubeVideoPlaybackStateEnum.PAUSED);
        break;
    }
  });

  useFurniRemovedEvent(objectId !== -1 && category !== -1, event => {
    if (event.id !== objectId || event.category !== category) return;

    onClose();
  });

  return {
    objectId,
    videoId,
    videoStart,
    videoEnd,
    currentVideoState,
    selectedVideo,
    playlists,
    canSetCustomVideo,
    customVideoUrl,
    customPictureUrl,
    overlayUrl,
    onClose,
    previous,
    next,
    pause,
    play,
    selectVideo,
    setCustomVideo,
    setCustomUploadedVideo,
    setCustomPicture,
    setOverlay,
  };
};

export const useFurnitureYoutubeWidget = useFurnitureYoutubeWidgetState;
EOF

# Full rewrite of the popup dialog: dual-mode player (native <video> for uploaded
# files vs the YouTube iframe) plus the upload UI with its required acknowledgment
# checkbox.
COPY <<'EOF' /build/apps/frontend/src/components/room/widgets/furniture/FurnitureYoutubeDisplayView.tsx
import {FC, useEffect, useRef, useState} from "react";
import {createPortal} from "react-dom";
import YouTube, {Options} from "react-youtube";
import {YouTubePlayer} from "youtube-player/dist/types";
import {FaPause, FaPlay, FaStop, FaTimes, FaVolumeMute, FaVolumeUp} from "react-icons/fa";
import {isRoomAudioEnabled, onRoomAudioPreferenceChanged, setRoomAudioEnabled} from "@nitro/renderer";

import {LocalizeText, YoutubeVideoPlaybackStateEnum} from "../../../../api";
import {AutoGrid, AutoGridProps, Button, Flex, LayoutGridItem, NitroCardContentView, NitroCardHeaderView, NitroCardView} from "../../../../common";
import {useFurnitureYoutubeWidget} from "../../../../hooks";

interface FurnitureYoutubeDisplayViewProps extends AutoGridProps {}

// Baked in at build time -- not a real access-control boundary by itself (the rank>=7
// gate that actually matters happens server-side, before this UI is ever shown to a
// non-rank-7 account), just enough to stop the upload endpoints being hit directly by
// someone who never went through the UI at all. Shared by both upload endpoints.
const MEDIA_UPLOAD_SECRET = "bb43881e1d188a55402eeeb84b1bafbaa59f3fe9a10b2fba809c6a84804112a2";
const CUSTOM_VIDEO_UPLOAD_URL = "https://atom.firecuba.com:8085/api/custom-video/upload";
const CUSTOM_PICTURE_UPLOAD_URL = "https://atom.firecuba.com:8085/api/custom-picture/upload";

const GALLERY_PICTURES: {id: string; label: string; url: string}[] = [
  {id: "aurora-gradient", label: "Aurora Gradient", url: "https://atom.firecuba.com:8083/gallery/pictures/aurora-gradient.jpg"},
  {id: "ocean-fade", label: "Ocean Fade", url: "https://atom.firecuba.com:8083/gallery/pictures/ocean-fade.jpg"},
  {id: "fractal-bloom", label: "Fractal Bloom", url: "https://atom.firecuba.com:8083/gallery/pictures/fractal-bloom.jpg"},
  {id: "cellular-pattern", label: "Cellular Pattern", url: "https://atom.firecuba.com:8083/gallery/pictures/cellular-pattern.jpg"},
  {id: "sunset-blaze", label: "Sunset Blaze", url: "https://atom.firecuba.com:8083/gallery/pictures/sunset-blaze.jpg"},
  {id: "neon-grid", label: "Neon Grid", url: "https://atom.firecuba.com:8083/gallery/pictures/neon-grid.jpg"},
];

const GALLERY_OVERLAYS: {id: string; label: string; url: string}[] = [
  {id: "gold-frame", label: "Gold Frame", url: "https://atom.firecuba.com:8083/gallery/overlays/gold-frame.png"},
  {id: "neon-border", label: "Neon Border", url: "https://atom.firecuba.com:8083/gallery/overlays/neon-border.png"},
  {id: "film-strip", label: "Film Strip", url: "https://atom.firecuba.com:8083/gallery/overlays/film-strip.png"},
  {id: "live-badge", label: "Live Badge", url: "https://atom.firecuba.com:8083/gallery/overlays/live-badge.png"},
  {id: "polaroid-frame", label: "Polaroid Frame", url: "https://atom.firecuba.com:8083/gallery/overlays/polaroid-frame.png"},
];

export const FurnitureYoutubeDisplayView: FC<{}> = FurnitureYoutubeDisplayViewProps => {
  const [player, setPlayer] = useState<any>(null);
  const videoRef = useRef<HTMLVideoElement>(null);
  const {
    objectId = -1,
    videoId = null,
    videoStart = 0,
    videoEnd = 0,
    currentVideoState = null,
    selectedVideo = null,
    playlists = [],
    canSetCustomVideo = false,
    customVideoUrl = null,
    customPictureUrl = null,
    overlayUrl = null,
    onClose = null,
    previous = null,
    next = null,
    pause = null,
    play = null,
    selectVideo = null,
    setCustomVideo = null,
    setCustomUploadedVideo = null,
    setCustomPicture = null,
    setOverlay = null,
  } = useFurnitureYoutubeWidget();

  const [customVideoInput, setCustomVideoInput] = useState("");
  const [showCustomVideoPanel, setShowCustomVideoPanel] = useState(true);
  const [showPicturePanel, setShowPicturePanel] = useState(true);
  const [showOverlayPanel, setShowOverlayPanel] = useState(true);
  const [lastOverlayUrl, setLastOverlayUrl] = useState<string>(null);
  const [uploadFile, setUploadFile] = useState<File>(null);
  const [uploadAckChecked, setUploadAckChecked] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState<string>(null);
  const [pictureUploadFile, setPictureUploadFile] = useState<File>(null);
  const [pictureUploadAckChecked, setPictureUploadAckChecked] = useState(false);
  const [pictureUploading, setPictureUploading] = useState(false);
  const [pictureUploadError, setPictureUploadError] = useState<string>(null);
  const [isMinimized, setIsMinimized] = useState(false);
  const [dockSide, setDockSide] = useState<"left" | "right">("right");
  const [roomAudioOn, setRoomAudioOn] = useState(isRoomAudioEnabled());

  useEffect(() => onRoomAudioPreferenceChanged(enabled => setRoomAudioOn(enabled)), []);

  const onToggleRoomAudio = () => setRoomAudioEnabled(!roomAudioOn);

  const hasCustomVideo = customVideoUrl && customVideoUrl.length > 0;
  const hasYoutubeVideo = videoId && videoId.length > 0 && !hasCustomVideo;
  const hasPicture = !hasCustomVideo && !hasYoutubeVideo && customPictureUrl && customPictureUrl.length > 0;
  const hasOverlay = overlayUrl && overlayUrl.length > 0;
  const hasContent = hasYoutubeVideo || hasCustomVideo || hasPicture;

  // Turns the currently-picked overlay on/off on the shared screen without losing
  // which one was picked -- off clears it for everyone in the room (empty URL),
  // back on re-applies the same frame from what was last selected.
  const onToggleOverlay = () => {
    if (hasOverlay) {
      setLastOverlayUrl(overlayUrl);
      setOverlay("");
    } else if (lastOverlayUrl) {
      setOverlay(lastOverlayUrl);
    }
  };

  // Safety-valve override: re-sends clear-then-reapply back to back so the room's
  // furniture screen redoes its overlay image load and repaint from scratch, in case
  // it's ever stuck out of sync with what's actually selected.
  const onForceRefreshOverlay = () => {
    if (!hasOverlay) return;

    const url = overlayUrl;

    setOverlay("");
    setOverlay(url);
  };

  const onStop = () => {
    pause();

    if (hasCustomVideo && videoRef.current) {
      videoRef.current.currentTime = 0;
    } else if (player) {
      player.seekTo(0);
    }
  };

  const onStateChange = (event: {target: YouTubePlayer; data: number}) => {
    setPlayer(event.target);

    if (objectId === -1) return;

    switch (event.target.getPlayerState()) {
      case -1:
      case 1:
        if (currentVideoState === 2) {
          //event.target.pauseVideo();
        }

        if (currentVideoState !== 1) play();
        return;
      case 2:
        if (currentVideoState !== 2) pause();
    }
  };

  useEffect(() => {
    if (currentVideoState === null) return;

    if (hasCustomVideo) {
      const el = videoRef.current;

      if (!el) return;

      if (currentVideoState === YoutubeVideoPlaybackStateEnum.PLAYING && el.paused) {
        el.play().catch(() => null);

        return;
      }

      if (currentVideoState === YoutubeVideoPlaybackStateEnum.PAUSED && !el.paused) {
        el.pause();

        return;
      }

      return;
    }

    if (!player) return;

    if (currentVideoState === YoutubeVideoPlaybackStateEnum.PLAYING && player.getPlayerState() !== YoutubeVideoPlaybackStateEnum.PLAYING) {
      player.playVideo();

      return;
    }

    if (currentVideoState === YoutubeVideoPlaybackStateEnum.PAUSED && player.getPlayerState() !== YoutubeVideoPlaybackStateEnum.PAUSED) {
      player.pauseVideo();

      return;
    }
  }, [currentVideoState, player, hasCustomVideo]);

  if (objectId === -1) return null;

  const youtubeOptions: Options = {
    height: "335",
    width: "500",
    playerVars: {
      autoplay: 1,
      disablekb: 1,
      controls: 0,
      origin: window.origin,
      modestbranding: 1,
      start: videoStart,
      end: videoEnd,
    },
  };

  // Shared between the full dialog and the minimized dock so there's only ever one
  // mounted <video>/<YouTube> instance -- switching between the two layouts just
  // moves this same content into a differently-sized container instead of
  // remounting the player (which would restart playback).
  const renderMediaContent = () => (
    <>
      {hasOverlay && hasContent && (
        <img
          src={overlayUrl}
          alt=""
          className="youtube-screen-overlay position-absolute w-100 h-100"
          style={{top: 0, left: 0, objectFit: "fill", pointerEvents: "none"}}
        />
      )}
      {hasYoutubeVideo && (
        <YouTube
          videoId={videoId}
          opts={youtubeOptions}
          onReady={event => setPlayer(event.target)}
          onStateChange={onStateChange}
          containerClassName={"youtubeContainer"}
        />
      )}
      {hasCustomVideo && (
        // eslint-disable-next-line jsx-a11y/media-has-caption
        <video
          ref={videoRef}
          src={customVideoUrl}
          autoPlay
          loop
          muted={roomAudioOn}
          controls={false}
          crossOrigin="anonymous"
          className="w-100 h-100"
          style={{objectFit: "contain", background: "black"}}
        />
      )}
      {hasPicture && (
        <img src={customPictureUrl} alt="" className="w-100 h-100" style={{objectFit: "contain", background: "black"}} />
      )}
      {!hasContent && (
        <div className="empty-video w-100 h-100 justify-content-center align-items-center d-flex">
          {LocalizeText("widget.furni.video_viewer.no_videos")}
        </div>
      )}
    </>
  );

  if (isMinimized) {
    // Plain label tab, deliberately not the live video/YouTube content: an embedded
    // YouTube iframe swallows clicks entirely (a real browser limitation -- clicks
    // inside a cross-origin iframe never bubble to the parent DOM), which made the
    // dock un-restorable whenever a YouTube video was playing. A plain div/text tab
    // has nothing that can eat the click.
    //
    // Rendered through the same portal every other game window uses
    // (DraggableWindow -> #draggable-windows-container), not inline in this
    // component's normal position in the tree -- a plain fixed-position div rendered
    // inline here sits under whatever ancestor happens to wrap this widget, which can
    // have its own stacking/positioning context that traps or covers it, making it
    // visible but unclickable. Mounting into the same container every reliable
    // window already uses sidesteps that entirely.
    const container = document.getElementById("draggable-windows-container");

    if (!container) return null;

    return createPortal(
      <div
        className="youtube-tv-mini-dock position-fixed d-flex align-items-center"
        style={{
          [dockSide]: 0,
          top: "35%",
          zIndex: 100000,
          pointerEvents: "auto",
          flexDirection: dockSide === "right" ? "row" : "row-reverse",
        }}
      >
        <div
          className="youtube-tv-mini-flip d-flex align-items-center justify-content-center cursor-pointer"
          style={{width: 16, height: 36, background: "rgba(0,0,0,0.65)", color: "#fff"}}
          onClick={() => setDockSide(dockSide === "right" ? "left" : "right")}
          title={LocalizeText("widget.furni.video_viewer.dock_side")}
        >
          {dockSide === "right" ? "◄" : "►"}
        </div>
        <div
          className="youtube-tv-mini-tab d-flex align-items-center cursor-pointer"
          style={{
            padding: "8px 14px",
            height: 36,
            background: "#222",
            color: "#fff",
            border: "2px solid #fff",
            borderRadius: dockSide === "right" ? "8px 0 0 8px" : "0 8px 8px 0",
            fontSize: 13,
            whiteSpace: "nowrap",
          }}
          onClick={() => setIsMinimized(false)}
          title={LocalizeText("widget.furni.video_viewer.restore")}
        >
          {LocalizeText("catalog.page.youtube_tvs")}
        </div>
      </div>,
      container
    );
  }

  const onUploadFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setUploadFile(event.target.files && event.target.files.length ? event.target.files[0] : null);
    setUploadError(null);
  };

  const onUploadClick = () => {
    if (!uploadFile || !uploadAckChecked || uploading) return;

    setUploading(true);
    setUploadError(null);

    const formData = new FormData();

    formData.append("secret", MEDIA_UPLOAD_SECRET);
    formData.append("video", uploadFile);

    fetch(CUSTOM_VIDEO_UPLOAD_URL, {method: "POST", body: formData})
      .then(response => {
        if (!response.ok) throw new Error("upload failed");

        return response.json();
      })
      .then(data => {
        setCustomUploadedVideo(data.url);
        setUploadFile(null);
        setUploadAckChecked(false);
      })
      .catch(() => setUploadError(LocalizeText("widget.furni.video_viewer.custom_video.upload_error")))
      .finally(() => setUploading(false));
  };

  const onPictureUploadFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setPictureUploadFile(event.target.files && event.target.files.length ? event.target.files[0] : null);
    setPictureUploadError(null);
  };

  const onPictureUploadClick = () => {
    if (!pictureUploadFile || !pictureUploadAckChecked || pictureUploading) return;

    setPictureUploading(true);
    setPictureUploadError(null);

    const formData = new FormData();

    formData.append("secret", MEDIA_UPLOAD_SECRET);
    formData.append("picture", pictureUploadFile);

    fetch(CUSTOM_PICTURE_UPLOAD_URL, {method: "POST", body: formData})
      .then(response => {
        if (!response.ok) throw new Error("upload failed");

        return response.json();
      })
      .then(data => {
        setCustomPicture(data.url);
        setPictureUploadFile(null);
        setPictureUploadAckChecked(false);
      })
      .catch(() => setPictureUploadError(LocalizeText("widget.furni.video_viewer.custom_picture.upload_error")))
      .finally(() => setPictureUploading(false));
  };

  return (
    <NitroCardView className="youtube-tv-widget position-relative">
      <NitroCardHeaderView headerText={LocalizeText("catalog.page.youtube_tvs")} onCloseClick={onClose} />
      <Flex
        center
        position="absolute"
        className="nitro-card-header-minimize cursor-pointer"
        style={{top: 6, right: 34}}
        onClick={() => setIsMinimized(true)}
        title={LocalizeText("widget.furni.video_viewer.minimize")}
      >
        <span style={{fontWeight: "bold", fontSize: 16, lineHeight: 1}}>─</span>
      </Flex>
      <NitroCardContentView>
        <div className="row w-100 h-100">
          <div className="youtube-video-container col-9 overflow-hidden d-flex flex-column">
            <div className="position-relative w-100 h-100 flex-grow-1">{renderMediaContent()}</div>
            {(hasYoutubeVideo || hasCustomVideo) && (
              <div className="youtube-playback-controls d-flex justify-content-center mt-1">
                <FaPlay className="cursor-pointer me-4" title={LocalizeText("widget.furni.video_viewer.play")} onClick={play} />
                <FaPause className="cursor-pointer me-4" title={LocalizeText("widget.furni.video_viewer.pause")} onClick={pause} />
                <FaStop className="cursor-pointer" title={LocalizeText("widget.furni.video_viewer.stop")} onClick={onStop} />
              </div>
            )}
            {hasCustomVideo && (
              <div className="youtube-room-audio-toggle d-flex justify-content-center align-items-center cursor-pointer mt-1" onClick={onToggleRoomAudio}>
                {roomAudioOn ? <FaVolumeUp className="me-2" /> : <FaVolumeMute className="me-2" />}
                <span className="small">
                  {LocalizeText(roomAudioOn ? "widget.furni.video_viewer.room_audio.on" : "widget.furni.video_viewer.room_audio.off")}
                </span>
              </div>
            )}
          </div>
          <div className="playlist-container col-3 d-flex flex-column">
            <span className="playlist-controls justify-content-center d-flex">
              <i className="icon icon-youtube-prev cursor-pointer" onClick={previous} />
              <i className="icon icon-youtube-next cursor-pointer" onClick={next} />
            </span>
            <div className="mb-1">{LocalizeText("widget.furni.video_viewer.playlists")}</div>
            <AutoGrid columnCount={1} columnMinWidth={80} columnMinHeight={100} className="mb-1" overflow="auto">
              {playlists &&
                playlists.map((entry, index) => {
                  return (
                    <LayoutGridItem key={index} onClick={event => selectVideo(entry.video)} itemActive={entry.video === selectedVideo}>
                      <b>{entry.title}</b>
                    </LayoutGridItem>
                  );
                })}
            </AutoGrid>
            {canSetCustomVideo && showCustomVideoPanel && (
              <div className="custom-video-input d-flex flex-column mt-1">
                <div className="d-flex justify-content-between align-items-center mb-1">
                  <span>{LocalizeText("widget.furni.video_viewer.custom_video.label")}</span>
                  <FaTimes className="cursor-pointer" onClick={() => setShowCustomVideoPanel(false)} />
                </div>
                <input
                  type="text"
                  className="form-control form-control-sm mb-1"
                  placeholder={LocalizeText("widget.furni.video_viewer.custom_video.placeholder")}
                  value={customVideoInput}
                  onChange={event => setCustomVideoInput(event.target.value)}
                />
                <Button
                  variant="success"
                  disabled={customVideoInput.trim().length === 0}
                  onClick={() => {
                    setCustomVideo(customVideoInput.trim());
                    setCustomVideoInput("");
                  }}
                  className="mb-2"
                >
                  {LocalizeText("widget.furni.video_viewer.custom_video.play")}
                </Button>

                <hr className="my-1" />

                <span className="mb-1">{LocalizeText("widget.furni.video_viewer.custom_video.upload_label")}</span>
                <input
                  type="file"
                  accept="video/mp4,video/webm"
                  className="form-control form-control-sm mb-1"
                  onChange={onUploadFileChange}
                />
                <div className="form-check mb-1">
                  <input
                    type="checkbox"
                    className="form-check-input"
                    id="customVideoUploadAck"
                    checked={uploadAckChecked}
                    onChange={event => setUploadAckChecked(event.target.checked)}
                  />
                  <label className="form-check-label small" htmlFor="customVideoUploadAck">
                    {LocalizeText("widget.furni.video_viewer.custom_video.upload_ack")}
                  </label>
                </div>
                {uploadError && <div className="text-danger small mb-1">{uploadError}</div>}
                <Button variant="success" disabled={!uploadFile || !uploadAckChecked || uploading} onClick={onUploadClick}>
                  {uploading
                    ? LocalizeText("widget.furni.video_viewer.custom_video.uploading")
                    : LocalizeText("widget.furni.video_viewer.custom_video.upload_button")}
                </Button>
              </div>
            )}
            {canSetCustomVideo && !showCustomVideoPanel && (
              <div className="custom-video-reopen cursor-pointer mt-1" onClick={() => setShowCustomVideoPanel(true)}>
                {LocalizeText("widget.furni.video_viewer.custom_video.reopen")}
              </div>
            )}
            {canSetCustomVideo && showPicturePanel && (
              <div className="custom-picture-input d-flex flex-column mt-1">
                <div className="d-flex justify-content-between align-items-center mb-1">
                  <span>{LocalizeText("widget.furni.video_viewer.custom_picture.label")}</span>
                  <FaTimes className="cursor-pointer" onClick={() => setShowPicturePanel(false)} />
                </div>
                <div className="custom-picture-gallery d-flex flex-wrap mb-2">
                  {GALLERY_PICTURES.map(picture => (
                    <img
                      key={picture.id}
                      src={picture.url}
                      alt={picture.label}
                      title={picture.label}
                      className={"custom-picture-thumb cursor-pointer" + (customPictureUrl === picture.url ? " active" : "")}
                      onClick={() => setCustomPicture(picture.url)}
                    />
                  ))}
                </div>

                <hr className="my-1" />

                <span className="mb-1">{LocalizeText("widget.furni.video_viewer.custom_picture.upload_label")}</span>
                <input
                  type="file"
                  accept="image/jpeg,image/png,image/gif"
                  className="form-control form-control-sm mb-1"
                  onChange={onPictureUploadFileChange}
                />
                <div className="form-check mb-1">
                  <input
                    type="checkbox"
                    className="form-check-input"
                    id="customPictureUploadAck"
                    checked={pictureUploadAckChecked}
                    onChange={event => setPictureUploadAckChecked(event.target.checked)}
                  />
                  <label className="form-check-label small" htmlFor="customPictureUploadAck">
                    {LocalizeText("widget.furni.video_viewer.custom_picture.upload_ack")}
                  </label>
                </div>
                {pictureUploadError && <div className="text-danger small mb-1">{pictureUploadError}</div>}
                <Button variant="success" disabled={!pictureUploadFile || !pictureUploadAckChecked || pictureUploading} onClick={onPictureUploadClick}>
                  {pictureUploading
                    ? LocalizeText("widget.furni.video_viewer.custom_picture.uploading")
                    : LocalizeText("widget.furni.video_viewer.custom_picture.upload_button")}
                </Button>
              </div>
            )}
            {canSetCustomVideo && !showPicturePanel && (
              <div className="custom-video-reopen cursor-pointer mt-1" onClick={() => setShowPicturePanel(true)}>
                {LocalizeText("widget.furni.video_viewer.custom_picture.reopen")}
              </div>
            )}
            {canSetCustomVideo && showOverlayPanel && (
              <div className="custom-overlay-input d-flex flex-column mt-1">
                <div className="d-flex justify-content-between align-items-center mb-1">
                  <span>{LocalizeText("widget.furni.video_viewer.overlay.label")}</span>
                  <FaTimes className="cursor-pointer" onClick={() => setShowOverlayPanel(false)} />
                </div>
                <div className="custom-picture-gallery d-flex flex-wrap mb-2">
                  {GALLERY_OVERLAYS.map(overlay => (
                    <img
                      key={overlay.id}
                      src={overlay.url}
                      alt={overlay.label}
                      title={overlay.label}
                      className={"custom-picture-thumb cursor-pointer" + (overlayUrl === overlay.url ? " active" : "")}
                      onClick={() => setOverlay(overlay.url)}
                    />
                  ))}
                </div>
                <Button variant={hasOverlay ? "danger" : "success"} disabled={!hasOverlay && !lastOverlayUrl} onClick={onToggleOverlay} className="mb-1">
                  {LocalizeText(hasOverlay ? "widget.furni.video_viewer.overlay.turn_off" : "widget.furni.video_viewer.overlay.turn_on")}
                </Button>
                <Button variant="secondary" disabled={!hasOverlay} onClick={onForceRefreshOverlay}>
                  {LocalizeText("widget.furni.video_viewer.overlay.force_refresh")}
                </Button>
              </div>
            )}
            {canSetCustomVideo && !showOverlayPanel && (
              <div className="custom-video-reopen cursor-pointer mt-1" onClick={() => setShowOverlayPanel(true)}>
                {LocalizeText("widget.furni.video_viewer.overlay.reopen")}
              </div>
            )}
          </div>
        </div>
      </NitroCardContentView>
    </NitroCardView>
  );
};
EOF


# The dialog's fixed height (380px) only ever had exactly enough room for the
# video itself -- the new Play/Pause/Stop row above gets pushed below that and
# clipped. Growing the dialog (and shrinking the video slightly) makes room.
COPY <<'EOF' /tmp/fix_youtube_widget_height.py
path = "/build/apps/frontend/src/components/room/widgets/furniture/FurnitureWidgets.scss"
content = open(path).read()

old = '''.youtube-tv-widget {
  width: 600px;
  height: 380px;'''
new = '''.youtube-tv-widget {
  width: 600px;
  height: 420px;'''
assert content.count(old) == 1, "fix_youtube_widget_height: anchor not found"
content = content.replace(old, new)

open(path, "w").write(content)
print("fix_youtube_widget_height: patched")
EOF
RUN python3 /tmp/fix_youtube_widget_height.py && rm /tmp/fix_youtube_widget_height.py

# Thumbnail grid for the picture-gallery panel added to the same widget.
COPY <<'EOF' /tmp/fix_youtube_widget_picture_gallery_css.py
path = "/build/apps/frontend/src/components/room/widgets/furniture/FurnitureWidgets.scss"
content = open(path).read()

old = '''.youtube-tv-widget {
  width: 600px;
  height: 420px;'''
new = old + '''

  .custom-picture-gallery {
    gap: 4px;
  }

  .custom-picture-thumb {
    width: 46px;
    height: 46px;
    object-fit: cover;
    border-radius: 3px;
    border: 2px solid transparent;

    &.active {
      border-color: #6cc417;
    }
  }'''
assert content.count(old) == 1, "fix_youtube_widget_picture_gallery_css: anchor not found"
content = content.replace(old, new)

open(path, "w").write(content)
print("fix_youtube_widget_picture_gallery_css: patched")
EOF
RUN python3 /tmp/fix_youtube_widget_picture_gallery_css.py && rm /tmp/fix_youtube_widget_picture_gallery_css.py

# Fixes a real upstream rendering bug affecting every dynamic-thumbnail furni item
# (all Video TVs, external image frames, guild forum boards, etc.), not just the
# custom-video feature above: the room's per-frame render loop only repaints a
# furniture item's sprites when something else changes it that frame (position,
# a fresh server update, animation). The thumbnail image itself loads
# asynchronously over the network, so by the time it's actually decoded and
# ready, that triggering frame has long since passed and nothing schedules
# another one -- the item is left showing its static "idle" art (e.g. this
# TV's baked-in "H" logo) forever, even though the real image loaded fine.
# Forcing one more updateModel()+updateSprites() pass the instant the image
# is ready closes that gap.
# Full-file rewrite: supersedes the old fix_dynamic_thumbnail_repaint and
# fix_thumbnail_no_outline patches (both folded in below, marked inline) and
# adds live video support. The static-thumbnail path (getThumbnailURL) is
# unchanged; a new parallel path (getVideoURL) lets a subclass supply a
# playing <video> source instead of a static image. When one is present, an
# off-DOM <video> is decoded into an off-DOM <canvas> on an interval (~30fps,
# matching normal video frame rate -- every tick re-runs the same
# render-to-texture isometric bake generateTransformedThumbnail does for the
# static case, not just a cheap pixel copy, so this is the more expensive of
# the two paths) and re-baked into the furniture's screen asset via the
# existing setThumbnailImages/addThumbnailAsset pipeline, the same one the
# static picture already uses. The per-frame source texture is created once
# and updated in place (baseTexture.update()) rather than recreated every
# tick, so this doesn't leak a new GPU texture 30 times a second over a
# multi-hour session.
COPY <<'EOF' /build/libs/renderer/src/nitro/room/object/visualization/furniture/FurnitureDynamicThumbnailVisualization.ts
import {SCALE_MODES} from "@pixi/constants";
import {Texture} from "@pixi/core";

import {IsometricImageFurniVisualization} from "./IsometricImageFurniVisualization";

export class FurnitureDynamicThumbnailVisualization extends IsometricImageFurniVisualization {
  private _cachedUrl: string;
  private _cachedVideoUrl: string;
  private _cachedOverlayUrl: string;
  private _videoElement: HTMLVideoElement;
  private _videoCanvas: HTMLCanvasElement;
  private _videoCanvasContext: CanvasRenderingContext2D;
  private _videoCanvasTexture: Texture;
  private _videoFrameInterval: number;
  private _baseImage: HTMLImageElement;
  private _overlayImage: HTMLImageElement;
  private _staticCanvas: HTMLCanvasElement;
  private _staticCanvasContext: CanvasRenderingContext2D;

  constructor() {
    super();

    this._cachedUrl = null;
    this._cachedVideoUrl = null;
    this._cachedOverlayUrl = null;
    this._videoElement = null;
    this._videoCanvas = null;
    this._videoCanvasContext = null;
    this._videoCanvasTexture = null;
    this._videoFrameInterval = null;
    this._baseImage = null;
    this._overlayImage = null;
    this._staticCanvas = null;
    this._staticCanvasContext = null;
    // fix_thumbnail_no_outline: the 40px padding border generateTransformedThumbnail
    // adds eats into the picture instead of growing the box, since the box is a fixed
    // asset size -- drop it so the picture fills the screen edge-to-edge.
    this._hasOutline = false;
  }

  protected override updateModel(scale: number): boolean {
    if (this.object) {
      const videoUrl = this.getVideoURL();

      if (this._cachedVideoUrl !== videoUrl) {
        this._cachedVideoUrl = videoUrl;
        // Force the static-thumbnail branch below to re-evaluate too, in case
        // we're switching back from video to a static picture (or vice versa).
        this._cachedUrl = null;

        this.stopVideoPlayback();

        if (videoUrl && videoUrl !== "") this.startVideoPlayback(videoUrl);
      }

      const overlayUrl = this.getOverlayURL();

      if (this._cachedOverlayUrl !== overlayUrl) {
        this._cachedOverlayUrl = overlayUrl;
        this._overlayImage = null;

        if (overlayUrl && overlayUrl !== "") {
          const overlayImage = new Image();

          overlayImage.src = overlayUrl;
          overlayImage.crossOrigin = "*";

          overlayImage.onload = () => {
            this._overlayImage = overlayImage;

            // Only relevant to the static-picture path -- an already-running video's
            // captureVideoFrame tick picks up this._overlayImage on its own within
            // one interval tick (at most 33ms), no forced repaint needed there.
            if (!this._videoElement) this.renderStaticComposite();
          };
        } else if (!this._videoElement) {
          this.renderStaticComposite();
        }
      }

      if (!videoUrl) {
        const thumbnailUrl = this.getThumbnailURL();

        if (this._cachedUrl !== thumbnailUrl) {
          this._cachedUrl = thumbnailUrl;

          if (this._cachedUrl && this._cachedUrl !== "") {
            const image = new Image();

            image.src = thumbnailUrl;
            image.crossOrigin = "*";

            image.onload = () => {
              if (this._baseImage !== image && this._cachedUrl !== thumbnailUrl) return;

              this._baseImage = image;
              this.renderStaticComposite();
            };
          } else {
            this._baseImage = null;
            this.setThumbnailImages(null);
          }
        }
      } else {
        this._baseImage = null;
      }
    }

    return super.updateModel(scale);
  }

  // Builds (or rebuilds) the static-picture texture from the currently loaded base
  // image, compositing the overlay image on top of it if one is loaded. Shared by
  // both the "base picture just loaded" and "overlay just loaded/cleared" paths so
  // either one arriving triggers a correct repaint regardless of arrival order.
  private renderStaticComposite(): void {
    if (!this._baseImage) return;

    let texture: Texture;

    if (this._overlayImage) {
      if (!this._staticCanvas) {
        this._staticCanvas = document.createElement("canvas");
        this._staticCanvasContext = this._staticCanvas.getContext("2d");
      }

      const width = this._baseImage.naturalWidth;
      const height = this._baseImage.naturalHeight;

      this._staticCanvas.width = width;
      this._staticCanvas.height = height;
      this._staticCanvasContext.clearRect(0, 0, width, height);
      this._staticCanvasContext.drawImage(this._baseImage, 0, 0, width, height);
      this._staticCanvasContext.drawImage(this._overlayImage, 0, 0, width, height);

      texture = Texture.from(this._staticCanvas);
    } else {
      texture = Texture.from(this._baseImage);
    }

    texture.baseTexture.scaleMode = SCALE_MODES.LINEAR;

    this.setThumbnailImages(texture);

    // fix_dynamic_thumbnail_repaint: the image decoded well after this frame's render
    // pass already ran; force one more pass now so the texture actually reaches the
    // screen instead of waiting on a server update that may never come. This has to
    // happen on the next animation frame, not synchronously right here: the
    // transformed-thumbnail texture is itself produced by a render-to-texture pass
    // (generateTransformedThumbnail), and doing that outside PIXI's normal per-frame
    // render tick produces garbage output (confirmed: calling it directly from this
    // callback always produced the exact same corrupted image, regardless of the
    // actual thumbnail content). The room's sprite canvas also keeps its own cache
    // keyed on updateSpriteCounter, which normally only advances inside the regular
    // per-frame update() call -- bumping it here too tells that cache this object's
    // sprites actually changed, or it never re-reads the new texture.
    requestAnimationFrame(() => {
      if (this._scale >= 0) {
        this.updateModel(this._scale);
        this.updateSprites(this._scale, true, 0);
        this.updateSpriteCounter++;
      }
    });
  }

  private startVideoPlayback(url: string): void {
    const video = document.createElement("video");

    video.src = url;
    video.crossOrigin = "anonymous";
    // The popup player already plays this same video with audio; muting the
    // in-room texture copy avoids doubling the sound for everyone in the room.
    video.muted = true;
    video.loop = true;
    video.playsInline = true;
    video.autoplay = true;
    video.play().catch(() => null);

    this._videoElement = video;
    this._videoCanvas = document.createElement("canvas");
    this._videoCanvasContext = this._videoCanvas.getContext("2d");
    this._videoFrameInterval = window.setInterval(() => this.captureVideoFrame(), 33);
  }

  private captureVideoFrame(): void {
    const video = this._videoElement;

    if (!video || video.readyState < 2 || video.videoWidth === 0) return;

    const canvas = this._videoCanvas;

    if (canvas.width !== video.videoWidth || canvas.height !== video.videoHeight) {
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;

      if (this._videoCanvasTexture) {
        this._videoCanvasTexture.destroy(true);
        this._videoCanvasTexture = null;
      }
    }

    this._videoCanvasContext.drawImage(video, 0, 0, canvas.width, canvas.height);

    if (this._overlayImage) this._videoCanvasContext.drawImage(this._overlayImage, 0, 0, canvas.width, canvas.height);

    if (!this._videoCanvasTexture) {
      this._videoCanvasTexture = Texture.from(canvas);
      this._videoCanvasTexture.baseTexture.scaleMode = SCALE_MODES.LINEAR;
    } else {
      this._videoCanvasTexture.baseTexture.update();
    }

    this.setThumbnailImages(this._videoCanvasTexture);

    if (this._scale >= 0) {
      this.updateModel(this._scale);
      this.updateSprites(this._scale, true, 0);
      this.updateSpriteCounter++;
    }
  }

  private stopVideoPlayback(): void {
    if (this._videoFrameInterval !== null) {
      window.clearInterval(this._videoFrameInterval);
      this._videoFrameInterval = null;
    }

    if (this._videoCanvasTexture) {
      this._videoCanvasTexture.destroy(true);
      this._videoCanvasTexture = null;
    }

    if (this._videoElement) {
      this._videoElement.pause();
      this._videoElement.removeAttribute("src");
      this._videoElement.load();
      this._videoElement = null;
    }

    this._videoCanvas = null;
    this._videoCanvasContext = null;
  }

  public override dispose(): void {
    this.stopVideoPlayback();

    super.dispose();
  }

  protected getThumbnailURL(): string {
    throw new Error("This method must be overridden!");
  }

  protected getVideoURL(): string {
    return null;
  }

  protected getOverlayURL(): string {
    return null;
  }
}
EOF

# Shared session-wide flag: does the player want to hear audio from custom-uploaded
# videos even when they haven't opened the Video TV's popup? Read by the furniture
# visualization above (the muted texture-capture <video> unmutes when this flips on,
# via fix_room_audio_preference_wiring.py below) and written by a toggle button in the
# popup. Browsers block unmuted autoplay without a prior user gesture, so this can
# only ever be turned on by an explicit button click, never automatically; that click
# is what makes the subsequent unmute reliable.
COPY <<'EOF' /build/libs/renderer/src/api/nitro/sound/RoomAudioPreference.ts
type RoomAudioPreferenceListener = (enabled: boolean) => void;

let roomAudioEnabled = false;
const listeners = new Set<RoomAudioPreferenceListener>();

export function isRoomAudioEnabled(): boolean {
  return roomAudioEnabled;
}

export function setRoomAudioEnabled(enabled: boolean): void {
  if (roomAudioEnabled === enabled) return;

  roomAudioEnabled = enabled;
  listeners.forEach(listener => listener(roomAudioEnabled));
}

export function onRoomAudioPreferenceChanged(listener: RoomAudioPreferenceListener): () => void {
  listeners.add(listener);

  return () => listeners.delete(listener);
}
EOF

COPY <<'EOF' /tmp/fix_room_audio_preference_wiring.py
# 1. Export the new module from the sound API barrel (already re-exported up through
# libs/renderer/src/api/index.ts -> libs/renderer/src/index.ts -> @nitro/renderer).
path = "/build/libs/renderer/src/api/nitro/sound/index.ts"
content = open(path).read()
old = 'export * from "./ISoundManager";\n'
assert content.count(old) == 1, "fix_room_audio_preference_wiring: sound index.ts anchor not found"
open(path, "w").write(content.replace(old, old + 'export * from "./RoomAudioPreference";\n'))

# 2. The texture-capture <video> (muted by default, one per viewer) respects the
# preference and reacts live if it changes while a video is already playing.
path = "/build/libs/renderer/src/nitro/room/object/visualization/furniture/FurnitureDynamicThumbnailVisualization.ts"
content = open(path).read()

old_import = 'import {SCALE_MODES} from "@pixi/constants";\nimport {Texture} from "@pixi/core";\n'
new_import = old_import + '\nimport {isRoomAudioEnabled, onRoomAudioPreferenceChanged} from "../../../../../api";\n'
assert content.count(old_import) == 1, "fix_room_audio_preference_wiring: visualization import anchor not found"
content = content.replace(old_import, new_import)

old_field = "  private _videoFrameInterval: number;\n"
new_field = old_field + "  private _unsubscribeRoomAudio: () => void;\n"
assert content.count(old_field) == 1, "fix_room_audio_preference_wiring: visualization field anchor not found"
content = content.replace(old_field, new_field)

old_ctor = "    this._videoCanvasTexture = null;\n    this._videoFrameInterval = null;\n"
new_ctor = old_ctor + "    this._unsubscribeRoomAudio = null;\n"
assert content.count(old_ctor) == 1, "fix_room_audio_preference_wiring: visualization constructor anchor not found"
content = content.replace(old_ctor, new_ctor)

old_start = '''    video.src = url;
    video.crossOrigin = "anonymous";
    // The popup player already plays this same video with audio; muting the
    // in-room texture copy avoids doubling the sound for everyone in the room.
    video.muted = true;
    video.loop = true;
    video.playsInline = true;
    video.autoplay = true;
    video.play().catch(() => null);

    this._videoElement = video;
    this._videoCanvas = document.createElement("canvas");
    this._videoCanvasContext = this._videoCanvas.getContext("2d");
    this._videoFrameInterval = window.setInterval(() => this.captureVideoFrame(), 33);'''
new_start = '''    video.src = url;
    video.crossOrigin = "anonymous";
    // Muted unless the viewer has explicitly opted into ambient room audio (see
    // RoomAudioPreference) -- otherwise the popup player is the only place this
    // video's audio plays, to avoid doubling the sound for everyone in the room.
    video.muted = !isRoomAudioEnabled();
    video.loop = true;
    video.playsInline = true;
    video.autoplay = true;
    video.play().catch(() => null);

    this._videoElement = video;
    this._videoCanvas = document.createElement("canvas");
    this._videoCanvasContext = this._videoCanvas.getContext("2d");
    this._videoFrameInterval = window.setInterval(() => this.captureVideoFrame(), 33);
    this._unsubscribeRoomAudio = onRoomAudioPreferenceChanged(enabled => {
      if (this._videoElement) this._videoElement.muted = !enabled;
    });'''
assert content.count(old_start) == 1, "fix_room_audio_preference_wiring: startVideoPlayback anchor not found"
content = content.replace(old_start, new_start)

old_stop = '''  private stopVideoPlayback(): void {
    if (this._videoFrameInterval !== null) {'''
new_stop = '''  private stopVideoPlayback(): void {
    if (this._unsubscribeRoomAudio) {
      this._unsubscribeRoomAudio();
      this._unsubscribeRoomAudio = null;
    }

    if (this._videoFrameInterval !== null) {'''
assert content.count(old_stop) == 1, "fix_room_audio_preference_wiring: stopVideoPlayback anchor not found"
content = content.replace(old_stop, new_stop)

open(path, "w").write(content)
print("fix_room_audio_preference_wiring: patched all files")
EOF
RUN python3 /tmp/fix_room_audio_preference_wiring.py && rm /tmp/fix_room_audio_preference_wiring.py

# The screen furniture's THUMBNAIL layer can now source from either a static
# picture URL (existing YouTube-thumbnail / custom-video-URL-as-picture path)
# or a live video URL (new: server sends this as FURNITURE_DATA["CUSTOM_VIDEO_URL"]
# when a rank-7 admin has set an uploaded video via SetCustomUploadedVideoEvent --
# see arcturus/patches/hotfix_youtube_custom_video.patch). Video takes priority
# over the static thumbnail whenever both are present.
COPY <<'EOF' /build/libs/renderer/src/nitro/room/object/visualization/furniture/FurnitureYoutubeVisualization.ts
import {RoomObjectVariable} from "../../../../../api";
import {FurnitureDynamicThumbnailVisualization} from "./FurnitureDynamicThumbnailVisualization";

export class FurnitureYoutubeVisualization extends FurnitureDynamicThumbnailVisualization {
  protected static THUMBNAIL_URL: string = "THUMBNAIL_URL";
  protected static CUSTOM_VIDEO_URL: string = "CUSTOM_VIDEO_URL";
  protected static OVERLAY_URL: string = "OVERLAY_URL";

  protected override getThumbnailURL(): string {
    if (!this.object) return null;

    const furnitureData = this.object.model.getValue<{[index: string]: string}>(RoomObjectVariable.FURNITURE_DATA);

    if (furnitureData) return furnitureData[FurnitureYoutubeVisualization.THUMBNAIL_URL] || null;

    return null;
  }

  protected override getVideoURL(): string {
    if (!this.object) return null;

    const furnitureData = this.object.model.getValue<{[index: string]: string}>(RoomObjectVariable.FURNITURE_DATA);

    if (furnitureData) return furnitureData[FurnitureYoutubeVisualization.CUSTOM_VIDEO_URL] || null;

    return null;
  }

  protected override getOverlayURL(): string {
    if (!this.object) return null;

    const furnitureData = this.object.model.getValue<{[index: string]: string}>(RoomObjectVariable.FURNITURE_DATA);

    if (furnitureData) return furnitureData[FurnitureYoutubeVisualization.OVERLAY_URL] || null;

    return null;
  }
}
EOF

# The real fix: generateTransformedThumbnail computes a scale/shear matrix meant to
# stretch the thumbnail up to the anchor static frame's size (e.g. 426x240), but
# PIXI's generateTexture() sizes its output texture from the sprite's own untransformed
# bounds, not its transformed (scaled) bounds -- so the resulting texture silently comes
# out at the ORIGINAL, pre-scale size (e.g. 360x220) with the scaled content clipped to
# fit. Passing an explicit region forces the output texture to actually be asset-sized,
# so it composites correctly with everything else that assumes that size.
COPY <<'EOF' /tmp/fix_thumbnail_transform_size.py
path = "/build/libs/renderer/src/nitro/room/object/visualization/furniture/IsometricImageFurniVisualization.ts"
content = open(path).read()

old_import = '''import {Matrix} from "@pixi/math";'''
new_import = '''import {Matrix, Rectangle} from "@pixi/math";'''
assert content.count(old_import) == 1, "fix_thumbnail_transform_size: import anchor not found"
content = content.replace(old_import, new_import)

old = '''    return TextureUtils.generateTexture(sprite);'''
new = '''    return TextureUtils.generateTexture(sprite, new Rectangle(0, 0, asset.width, asset.height));'''
assert content.count(old) == 1, "fix_thumbnail_transform_size: anchor not found"
content = content.replace(old, new)

open(path, "w").write(content)
print("fix_thumbnail_transform_size: patched")
EOF
RUN python3 /tmp/fix_thumbnail_transform_size.py && rm /tmp/fix_thumbnail_transform_size.py

# The direction 0/4 case applied an isometric shear (matrix.b) so the thumbnail would
# skew to sit flush with the angled floor/wall the way the room's other flat art does.
# For this item the admin wants the picture to face the camera flat, like a normal
# poster, regardless of which way the room's walls happen to angle -- so drop the
# shear for every direction and just scale.
COPY <<'EOF' /tmp/fix_thumbnail_flat_no_shear.py
path = "/build/libs/renderer/src/nitro/room/object/visualization/furniture/IsometricImageFurniVisualization.ts"
content = open(path).read()

old = '''    switch (this.direction) {
      case 2:
        matrix.a = difference;
        matrix.b = -0.5 * difference;
        matrix.c = 0;
        matrix.d = difference * scale;
        matrix.tx = 0;
        matrix.ty = 0.5 * difference * texture.width;
        break;
      case 0:
      case 4:
        matrix.a = difference;
        matrix.b = 0.5 * difference;
        matrix.c = 0;
        matrix.d = difference * scale;
        matrix.tx = 0;
        matrix.ty = 0;
        break;
      default:
        matrix.a = difference;
        matrix.b = 0;
        matrix.c = 0;
        matrix.d = difference;
        matrix.tx = 0;
        matrix.ty = 0;'''
new = '''    switch (this.direction) {
      default:
        matrix.a = difference;
        matrix.b = 0;
        matrix.c = 0;
        matrix.d = difference;
        matrix.tx = 0;
        matrix.ty = 0;'''
assert content.count(old) == 1, "fix_thumbnail_flat_no_shear: anchor not found"
content = content.replace(old, new)

open(path, "w").write(content)
print("fix_thumbnail_flat_no_shear: patched")
EOF
RUN python3 /tmp/fix_thumbnail_flat_no_shear.py && rm /tmp/fix_thumbnail_flat_no_shear.py

# User macro bar: click another player's avatar to select them as a target, then a
# small side-docked bar of icon buttons lets you throw a cosmetic effect at them, have
# them walk over to you, or start a whisper -- available to any player on any other
# player (no rank gate). Mirrors the "click furni -> popup" pattern already used for
# the Video TV widget, but triggered by avatar selection instead, and (like the Video
# TV minimize dock) mounted through the same createPortal target every other game
# window uses so it actually receives clicks.
COPY <<'EOF' /build/libs/renderer/src/nitro/communication/messages/outgoing/room/unit/ThrowEffectAtUserMessageComposer.ts
import {IMessageComposer} from "../../../../../../api";

export class ThrowEffectAtUserMessageComposer implements IMessageComposer<ConstructorParameters<typeof ThrowEffectAtUserMessageComposer>> {
  private _data: ConstructorParameters<typeof ThrowEffectAtUserMessageComposer>;

  constructor(userId: number, effectId: number) {
    this._data = [userId, effectId];
  }

  public getMessageArray() {
    return this._data;
  }

  public dispose(): void {
    return;
  }
}
EOF

COPY <<'EOF' /build/libs/renderer/src/nitro/communication/messages/outgoing/room/unit/PullUserMessageComposer.ts
import {IMessageComposer} from "../../../../../../api";

export class PullUserMessageComposer implements IMessageComposer<ConstructorParameters<typeof PullUserMessageComposer>> {
  private _data: ConstructorParameters<typeof PullUserMessageComposer>;

  constructor(userId: number) {
    this._data = [userId];
  }

  public getMessageArray() {
    return this._data;
  }

  public dispose(): void {
    return;
  }
}
EOF

COPY <<'EOF' /tmp/fix_user_macro_client_wire.py
# 1. New outgoing headers (mirror server Incoming.throwEffectAtUserEvent = 32006,
# Incoming.pullUserEvent = 32007).
path = "/build/libs/renderer/src/nitro/communication/messages/outgoing/OutgoingHeader.ts"
content = open(path).read()
old = "  public static SET_OVERLAY = 32005;\n"
new = old + "  public static THROW_EFFECT_AT_USER = 32006;\n  public static PULL_USER = 32007;\n"
assert content.count(old) == 1, "fix_user_macro_client_wire: OutgoingHeader.ts anchor not found"
open(path, "w").write(content.replace(old, new))

# 2. Export both composers from the room/unit outgoing barrel.
path = "/build/libs/renderer/src/nitro/communication/messages/outgoing/room/unit/index.ts"
content = open(path).read()
old = 'export * from "./RoomUnitGiveHandItemComposer";\n'
assert content.count(old) == 1, "fix_user_macro_client_wire: room/unit outgoing index.ts anchor not found"
new = old + 'export * from "./ThrowEffectAtUserMessageComposer";\nexport * from "./PullUserMessageComposer";\n'
open(path, "w").write(content.replace(old, new))

# 3. Register both with NitroMessages.
path = "/build/libs/renderer/src/nitro/communication/NitroMessages.ts"
content = open(path).read()

old_import = "  RoomUnitGiveHandItemComposer,\n"
assert content.count(old_import) == 1, "fix_user_macro_client_wire: NitroMessages.ts import anchor not found"
content = content.replace(old_import, old_import + "  ThrowEffectAtUserMessageComposer,\n  PullUserMessageComposer,\n")

old_reg = "    this._composers.set(OutgoingHeader.UNIT_GIVE_HANDITEM, RoomUnitGiveHandItemComposer);\n"
assert content.count(old_reg) == 1, "fix_user_macro_client_wire: NitroMessages.ts registration anchor not found"
new_reg = (
    old_reg
    + "    this._composers.set(OutgoingHeader.THROW_EFFECT_AT_USER, ThrowEffectAtUserMessageComposer);\n"
    + "    this._composers.set(OutgoingHeader.PULL_USER, PullUserMessageComposer);\n"
)
content = content.replace(old_reg, new_reg)

open(path, "w").write(content)
print("fix_user_macro_client_wire: patched all files")
EOF
RUN python3 /tmp/fix_user_macro_client_wire.py && rm /tmp/fix_user_macro_client_wire.py

COPY <<'EOF' /build/apps/frontend/src/hooks/rooms/widgets/useUserMacroWidget.ts
import {PullUserMessageComposer, RoomObjectCategory, RoomObjectType, ThrowEffectAtUserMessageComposer} from "@nitro/renderer";
import {useState} from "react";

import {
  DispatchUiEvent,
  GetSessionDataManager,
  RoomWidgetUpdateChatInputContentEvent,
  RoomWidgetUpdateRoomObjectEvent,
  SendMessageComposer,
} from "../../../api";
import {useUiEvent} from "../../events";
import {useObjectDeselectedEvent, useObjectSelectedEvent} from "../engine";
import {useRoom} from "../useRoom";

const useUserMacroWidgetState = () => {
  const [targetUserId, setTargetUserId] = useState(-1);
  const [targetRoomIndex, setTargetRoomIndex] = useState(-1);
  const [targetName, setTargetName] = useState<string>(null);
  const {roomSession = null} = useRoom();

  const clearTarget = () => {
    setTargetUserId(-1);
    setTargetRoomIndex(-1);
    setTargetName(null);
  };

  useObjectSelectedEvent(event => {
    if (!roomSession || event.category !== RoomObjectCategory.UNIT) {
      clearTarget();
      return;
    }

    const userData = roomSession.userDataManager.getUserDataByIndex(event.id);

    if (!userData || userData.type !== RoomObjectType.USER || userData.webID === GetSessionDataManager().userId) {
      clearTarget();
      return;
    }

    setTargetUserId(userData.webID);
    setTargetRoomIndex(event.id);
    setTargetName(userData.name);
  });

  useObjectDeselectedEvent(() => clearTarget());

  useUiEvent<RoomWidgetUpdateRoomObjectEvent>(RoomWidgetUpdateRoomObjectEvent.USER_REMOVED, event => {
    if (event.id === targetRoomIndex) clearTarget();
  });

  const throwEffect = (effectId: number) => {
    if (targetUserId === -1) return;

    SendMessageComposer(new ThrowEffectAtUserMessageComposer(targetUserId, effectId));
  };

  const pullUser = () => {
    if (targetUserId === -1) return;

    SendMessageComposer(new PullUserMessageComposer(targetUserId));
  };

  const messageUser = () => {
    if (!targetName) return;

    DispatchUiEvent(new RoomWidgetUpdateChatInputContentEvent(RoomWidgetUpdateChatInputContentEvent.WHISPER, targetName));
  };

  return {
    targetUserId,
    targetRoomIndex,
    targetName,
    throwEffect,
    pullUser,
    messageUser,
  };
};

export const useUserMacroWidget = useUserMacroWidgetState;
EOF

COPY <<'EOF' /tmp/fix_user_macro_hook_barrel.py
path = "/build/apps/frontend/src/hooks/rooms/widgets/index.ts"
content = open(path).read()
old = 'export * from "./useAvatarInfoWidget";\n'
assert content.count(old) == 1, "fix_user_macro_hook_barrel: anchor not found"
open(path, "w").write(content.replace(old, old + 'export * from "./useUserMacroWidget";\n'))
print("fix_user_macro_hook_barrel: patched")
EOF
RUN python3 /tmp/fix_user_macro_hook_barrel.py && rm /tmp/fix_user_macro_hook_barrel.py

COPY <<'EOF' /build/apps/frontend/src/components/room/widgets/user-macros/UserMacroBarView.tsx
import {FC} from "react";
import {createPortal} from "react-dom";

import {LocalizeText} from "../../../../api";
import {useUserMacroWidget} from "../../../../hooks";

const EFFECTS: {id: number; emoji: string; labelKey: string}[] = [
  {id: 9, emoji: "\u{1F496}", labelKey: "widget.user_macros.effect.love"},
  {id: 7, emoji: "\u{1F98B}", labelKey: "widget.user_macros.effect.butterflies"},
  {id: 4, emoji: "✨", labelKey: "widget.user_macros.effect.twinkle"},
  {id: 13, emoji: "\u{1F47B}", labelKey: "widget.user_macros.effect.ghost"},
];

const BUTTON_STYLE: React.CSSProperties = {
  width: 34,
  height: 34,
  borderRadius: "50%",
  background: "#fff",
  border: "2px solid #222",
  fontSize: 18,
};

export const UserMacroBarView: FC<{}> = props => {
  const {targetUserId = -1, targetName = null, throwEffect = null, pullUser = null, messageUser = null} = useUserMacroWidget();

  if (targetUserId === -1) return null;

  const container = document.getElementById("draggable-windows-container");

  if (!container) return null;

  return createPortal(
    <div
      className="user-macro-bar position-fixed d-flex flex-column align-items-center"
      style={{right: 6, top: "40%", zIndex: 100000, pointerEvents: "auto", gap: 6}}
    >
      <div className="user-macro-bar-label" style={{background: "#222", color: "#fff", padding: "4px 8px", borderRadius: 6, fontSize: 12, whiteSpace: "nowrap"}}>
        {targetName}
      </div>
      {EFFECTS.map(effect => (
        <div
          key={effect.id}
          className="user-macro-bar-btn cursor-pointer d-flex align-items-center justify-content-center"
          style={BUTTON_STYLE}
          title={LocalizeText(effect.labelKey)}
          onClick={() => throwEffect(effect.id)}
        >
          {effect.emoji}
        </div>
      ))}
      <div
        className="user-macro-bar-btn cursor-pointer d-flex align-items-center justify-content-center"
        style={BUTTON_STYLE}
        title={LocalizeText("widget.user_macros.pull")}
        onClick={() => pullUser()}
      >
        {"\u{1F6B6}"}
      </div>
      <div
        className="user-macro-bar-btn cursor-pointer d-flex align-items-center justify-content-center"
        style={BUTTON_STYLE}
        title={LocalizeText("widget.user_macros.message")}
        onClick={() => messageUser()}
      >
        {"\u{1F4AC}"}
      </div>
    </div>,
    container
  );
};
EOF

COPY <<'EOF' /tmp/fix_user_macro_bar_wireup.py
path = "/build/apps/frontend/src/components/room/widgets/RoomWidgetsView.tsx"
content = open(path).read()

old_import = 'import {WordQuizWidgetView} from "./word-quiz/WordQuizWidgetView";\n'
assert content.count(old_import) == 1, "fix_user_macro_bar_wireup: import anchor not found"
new_import = old_import + 'import {UserMacroBarView} from "./user-macros/UserMacroBarView";\n'
content = content.replace(old_import, new_import)

old_jsx = "      <FriendRequestWidgetView />\n    </>"
assert content.count(old_jsx) == 1, "fix_user_macro_bar_wireup: JSX anchor not found"
new_jsx = "      <FriendRequestWidgetView />\n      <UserMacroBarView />\n    </>"
content = content.replace(old_jsx, new_jsx)

open(path, "w").write(content)
print("fix_user_macro_bar_wireup: patched")
EOF
RUN python3 /tmp/fix_user_macro_bar_wireup.py && rm /tmp/fix_user_macro_bar_wireup.py

RUN npm install --force
RUN npm install --save-dev nx
RUN npx nx build frontend

# Safari/iOS landscape fixes: anchor the html/body 100% height chain that
# Safari's viewport model needs (Chrome tolerates the missing html{height}
# rule, Safari does not), add dynamic-viewport-height + safe-area-inset
# fallbacks for notched iPhones, and register the missing
# apple-mobile-web-app-capable meta tag alongside its existing siblings.
RUN cat <<'EOF' > /build/dist/apps/frontend/safari-fix.css
html {
    height: 100%;
    height: -webkit-fill-available;
}
body {
    min-height: 100vh;
    min-height: -webkit-fill-available;
    min-height: 100dvh;
    padding-left: env(safe-area-inset-left);
    padding-right: env(safe-area-inset-right);
    padding-top: env(safe-area-inset-top);
    padding-bottom: env(safe-area-inset-bottom);
}
#root {
    min-height: 100dvh;
}
EOF
RUN sed -i \
    -e 's#<meta name="viewport" content="width=device-width, initial-scale=1, minimum-scale=1, maximum-scale=1" />#<meta name="viewport" content="width=device-width, initial-scale=1, minimum-scale=1, maximum-scale=1, viewport-fit=cover" />#' \
    -e 's#<meta name="mobile-web-app-capable" content="yes">#<meta name="mobile-web-app-capable" content="yes">\n    <meta name="apple-mobile-web-app-capable" content="yes" />#' \
    -e 's#</head>#    <link rel="stylesheet" href="/safari-fix.css">\n  </head>#' \
    /build/dist/apps/frontend/index.html



FROM nginx:alpine

COPY --from=builder /build/dist/apps/frontend/ /usr/share/nginx/html/
