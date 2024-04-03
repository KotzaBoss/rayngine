/*******************************************************************************************
*
*   ModelWindow v1.0.0 - Tool Description
*
*   MODULE USAGE:
*       #define GUI_MODELWINDOW_IMPLEMENTATION
*       #include "gui_ModelWindow.h"
*
*       INIT: GuiModelWindowState state = InitGuiModelWindow();
*       DRAW: GuiModelWindow(&state);
*
*   LICENSE: Propietary License
*
*   Copyright (c) 2022 raylib technologies. All Rights Reserved.
*
*   Unauthorized copying of this file, via any medium is strictly prohibited
*   This project is proprietary and confidential unless the owner allows
*   usage in any other form by expresely written permission.
*
**********************************************************************************************/

#include "raylib.h"

// WARNING: raygui implementation is expected to be defined before including this header
#undef RAYGUI_IMPLEMENTATION
#include "raygui.h"

#include <string.h>     // Required for: strcpy()

#ifndef GUI_MODELWINDOW_H
#define GUI_MODELWINDOW_H

typedef struct {
    bool ModelWindowActive;

    Rectangle layoutRecs[1];

    // Custom state variables (depend on development software)
    // NOTE: This variables should be added manually if required

} GuiModelWindowState;

#ifdef __cplusplus
extern "C" {            // Prevents name mangling of functions
#endif

//----------------------------------------------------------------------------------
// Defines and Macros
//----------------------------------------------------------------------------------
//...

//----------------------------------------------------------------------------------
// Types and Structures Definition
//----------------------------------------------------------------------------------
// ...

//----------------------------------------------------------------------------------
// Module Functions Declaration
//----------------------------------------------------------------------------------
GuiModelWindowState InitGuiModelWindow(void);
void GuiModelWindow(GuiModelWindowState *state);

#ifdef __cplusplus
}
#endif

#endif // GUI_MODELWINDOW_H

/***********************************************************************************
*
*   GUI_MODELWINDOW IMPLEMENTATION
*
************************************************************************************/
#if defined(GUI_MODELWINDOW_IMPLEMENTATION)

#include "raygui.h"

//----------------------------------------------------------------------------------
// Global Variables Definition
//----------------------------------------------------------------------------------
//...

//----------------------------------------------------------------------------------
// Internal Module Functions Definition
//----------------------------------------------------------------------------------
//...

//----------------------------------------------------------------------------------
// Module Functions Definition
//----------------------------------------------------------------------------------
GuiModelWindowState InitGuiModelWindow(void)
{
    GuiModelWindowState state = { 0 };

    state.ModelWindowActive = true;

    state.layoutRecs[0] = (Rectangle){ 200, 72, 584, 408 };

    // Custom variables initialization

    return state;
}

void GuiModelWindow(GuiModelWindowState *state)
{
    if (state->ModelWindowActive)
    {
        state->ModelWindowActive = !GuiWindowBox(state->layoutRecs[0], "SAMPLE TEXT");
    }
}

#endif // GUI_MODELWINDOW_IMPLEMENTATION
