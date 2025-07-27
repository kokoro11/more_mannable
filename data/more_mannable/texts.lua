local Text = mods.moreMannable.Text
local TextCollection = mods.moreMannable.TextCollection

local TEXTS = TextCollection()
mods.moreMannable.TEXTS = TEXTS

TEXTS.AUX_OFF_TOOLTIP = Text {
    [''] = [[Current mannable systems and manning bonuses:
Oxygen: Doubles the speed of oxygen refill.
Drones: Increases drone operating speed by 20%%.
Artillery: Boosts recharge speed by 10%%.
Temporal: Disabled.
Cloaking: Disabled.
Mind Control: Disabled.
Hacking: Disabled.

Manning skill levels: Disabled.
Enable ADVANCED MANNING option for more mannable systems and manning skill levels.]],
    ['zh-Hans'] = [[目前已启用的可操纵系统和操纵加成：
氧气：+100%%氧气填充速度。
无人机：+20%%无人机运行速度。
巨炮：+10%%巨炮充能速度。
时流：已禁用。
隐形：已禁用。
心控：已禁用。
黑客：已禁用。

技能等级：已禁用。
启用ADVANCED MANNING选项以使更多系统可操纵并启用技能等级。]],
}

TEXTS.AUX_ON_TOOLTIP = Text {
    [''] = [[Current mannable systems and manning bonuses:
Oxygen: Increases oxygen refill speed by 100/200/300%%.
Drones: Increases drone operating speed by 20/30/40%%.
Artillery: Boosts recharge speed by 10/20/30%%.
Temporal: Reduces system cooldown by 20/33/43%%.
Cloaking: Increases evasion by 40%% while cloaking is active.
+ (Level 1) Reduces system cooldown by 20%%.
+ (Level 2) Increases evasion by 10%% while system is powered.
Mind Control: Extends mind control duration by 25%%.
+ (Level 1) Reduces system cooldown by 50%%.
+ (Level 2) Mind controlled crew acts twice as fast.
Hacking: Accelerates hacking speed by 25%%.
+ (Level 1) Reduces system cooldown by 20%%.
+ (Level 2) Counters enemy's hacking drone.

Crew gain experience simply by manning a system or by being at the station when the system is used during combat.
A single crew member can only gain up to %s skill points for the same system per jump.
Crew drones cannot gain skills.]],
    ['zh-Hans'] = [[目前已启用的可操纵系统和操纵加成：
氧气：+100/200/300%%氧气填充速度。
无人机：+20/30/40%%无人机运行速度。
巨炮：+10/20/30%%巨炮充能速度。
时流：-20/33/43%%系统冷却时间。
隐形：启用时+40%%闪避率。
+（等级1）-20%%系统冷却时间。
+（等级2）系统有能量时+10%%闪避率。
心控：心控时间+25%%。
+（等级1）-50%%系统冷却时间。
+（等级2）被心控船员行动速度翻倍。
黑客：+25%%黑客速度。
+（等级1）-20%%系统冷却时间。
+（等级2）能够反制敌舰的黑客无人机。

要训练船员某个系统的技能，请在战斗中操纵或使用该系统。
一次跃迁一位船员对相同的系统最多只能获取%s点技能点数。
船员无人机无法训练技能。]],
}

TEXTS.MANNING_BONUS = Text {
    [''] = "\n\nManning bonus: ",
    ['zh-Hans'] = "\n\n操纵加成：",
}

TEXTS.MANNING_BONUS_UNKNOWN = Text {
    [''] = [[Unknown]],
    ['zh-Hans'] = [[未知]],
}
TEXTS.MANNING_BONUS_ENTRY = TextCollection(TEXTS.MANNING_BONUS_UNKNOWN)
TEXTS.MANNING_BONUS_ENTRY[2] = Text { -- Oxygen
    [''] = [[Increases oxygen refill speed by 100/200/300%%]],
    ['zh-Hans'] = [[+100/200/300%%氧气填充速度]],
}
TEXTS.MANNING_BONUS_ENTRY[4] = Text { -- Drones
    [''] = [[Increases drone operating speed by 20/30/40%%]],
    ['zh-Hans'] = [[+20/30/40%%无人机运行速度]],
}
TEXTS.MANNING_BONUS_ENTRY[11] = Text { -- Artillery
    [''] = [[Boosts recharge speed by 10/20/30%%]],
    ['zh-Hans'] = [[+10/20/30%%巨炮充能速度]],
}
TEXTS.MANNING_BONUS_ENTRY[10] = Text { -- Cloaking
    [''] = [[Increases evasion by 40%% while cloaking is active
+ (Level 1) Reduces system cooldown by 20%%
+ (Level 2) Increases evasion by 10%% while system is powered]],
    ['zh-Hans'] = [[启用时+40%%闪避率。
+（等级1）-20%%系统冷却时间。
+（等级2）系统有能量时+10%%闪避率。]],
}
TEXTS.MANNING_BONUS_ENTRY[14] = Text { -- Mind Control
    [''] = [[Extends mind control duration by 25%%
+ (Level 1) Reduces system cooldown by 50%%
+ (Level 2) Mind controlled crew acts twice as fast]],
    ['zh-Hans'] = [[心控时间+25%%。
+（等级1）-50%%系统冷却时间。
+（等级2）被心控船员行动速度翻倍。]],
}
TEXTS.MANNING_BONUS_ENTRY[15] = Text { -- Hacking
    [''] = [[Accelerates hacking speed by 25%%
+ (Level 1) Reduces system cooldown by 20%%
+ (Level 2) Counters enemy's hacking drone]],
    ['zh-Hans'] = [[+25%%黑客速度。
+（等级1）-20%%系统冷却时间。
+（等级2）能够反制敌舰的黑客无人机。]],
}
TEXTS.MANNING_BONUS_ENTRY[20] = Text { -- Temporal
    [''] = [[Reduces system cooldown by 20/33/43%%]],
    ['zh-Hans'] = [[-20/33/43%%系统冷却时间]],
}

TEXTS.SKILLS = Text {
    [''] = [[Skills:]],
    ['zh-Hans'] = [[技能：]],
}

TEXTS.NO_SKILLS = Text {
    [''] = [[No trained skills]],
    ['zh-Hans'] = [[无技能]],
}

TEXTS.SKILL_ENTRY = Text {
    [''] = [[%s: %s (Exp: %s/%s)%s]],
    ['zh-Hans'] = [[%s：%s（经验：%s/%s）%s]],
}

TEXTS.CANNOT_TRAIN = Text {
    [''] = "\n- Cannot gain more exp this jump",
    ['zh-Hans'] = "\n- 本次跃迁无法获取更多经验",
}

TEXTS.SKILL_ENTRY_MAXLEVEL = Text {
    [''] = [[%s: %s (Maxxed)]],
    ['zh-Hans'] = [[%s：%s（已最大）]],
}

TEXTS.SYS_NAME_UNKNOWN = Text {
    [''] = [[Unknown System]],
    ['zh-Hans'] = [[未知系统]],
}
TEXTS.SYS_NAMES = TextCollection(TEXTS.SYS_NAME_UNKNOWN)
TEXTS.SYS_NAMES[2] = Text {
    [''] = [[Oxygen]],
    ['zh-Hans'] = [[氧气]],
}
TEXTS.SYS_NAMES[4] = Text {
    [''] = [[Drones]],
    ['zh-Hans'] = [[无人机]],
}
TEXTS.SYS_NAMES[11] = Text {
    [''] = [[Artillery]],
    ['zh-Hans'] = [[巨炮]],
}
TEXTS.SYS_NAMES[10] = Text {
    [''] = [[Cloaking]],
    ['zh-Hans'] = [[隐形]],
}
TEXTS.SYS_NAMES[14] = Text {
    [''] = [[Mind Control]],
    ['zh-Hans'] = [[心控]],
}
TEXTS.SYS_NAMES[15] = Text {
    [''] = [[Hacking]],
    ['zh-Hans'] = [[黑客]],
}
TEXTS.SYS_NAMES[20] = Text {
    [''] = [[Temporal]],
    ['zh-Hans'] = [[时流]],
}

TEXTS.SKILL_LEVEL_UNKNOWN = Text {
    [''] = [[Lv. ?]],
    ['zh-Hans'] = [[等级未知]],
}
TEXTS.SKILL_LEVEL = TextCollection(TEXTS.SKILL_LEVEL_UNKNOWN)
TEXTS.SKILL_LEVEL[1] = Text {
    [''] = [[Lv. 0]],
    ['zh-Hans'] = [[等级0]],
}
TEXTS.SKILL_LEVEL[2] = Text {
    [''] = [[Lv. 1]],
    ['zh-Hans'] = [[等级1]],
}
TEXTS.SKILL_LEVEL[3] = Text {
    [''] = [[Lv. 2]],
    ['zh-Hans'] = [[等级2]],
}
