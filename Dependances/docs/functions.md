# Eyes Of Application PowerShell functions reference manual

This document enumerates the embedded EOA functions used for EOA scenario

---
## AddValues ($aNiveau, $aMsg)

Adds lines to the log file with date, severity, and information.

### Parameters
| param   | type   | mandatory | description |
|---------|--------|-----------|-------------|
| aNiveau | string | yes       | severity of the log entry |
| aMsg    |string  | yes       | message to log |

### Return
None

### Example

    AddValues ("INFO", "$ProgExe (NoArgument)")

> 05/19/2017 17:12:58 (INFO): PID ---> 212

---
## Click-MouseButton button

Manage  mouse actions:
- left/center/right click
- double click
- scroll wheel
- mouse movements 

### Parameters

| param   | type   | mandatory | description |
|---------|--------|-----------|-------------|
| button  | string | yes       | button to click. Possibles values are : **double**, **left**, **right**, **middle** |

### Return
None

### Example

    Click-MouseButton double

---
## Send-SpecialKeys KeysToPress

Emulates a key press on the keyborad's special key

### Parameters

| param   | type   | mandatory | description |
|---------|--------|-----------|-------------|
| KeysToPress | string | yes | keycode to send |

| Valid strings for KeysToPress | description |
|-------------------------------|-------------|
| "{DOUBLEQUOTE}" | send keycode for " character |
| "{F1}"          | send keycode for [F1] key |
| "{F2}"          | send keycode for [F2] key |
| "{F3}"          | send keycode for [F3] key |
| "{F4}"          | send keycode for [F4] key |
| "{F5}"          | send keycode for [F5] key |
| "{F6}"          | send keycode for [F6] key |
| "{F7}"          | send keycode for [F7] key |
| "{F8}"          | send keycode for [F8] key |
| "{F9}"          | send keycode for [F9] key |
| "{F10}"         | send keycode for [F10] key |
| "{F11}"         | send keycode for [F11] key |
| "{F12}"         | send keycode for [F12] key |
| "{ALTF4}"       | send keycodes for [ALT] + [F4] keys combination |
| "{CTRL_a}"      | send keycodes for [CONTROL] + [a] keys combination |
| "{CTRL_c}"      | send keycodes for [CONTROL] + [c] keys combination |
| "{CTRL_v}"      | send keycodes for [CONTROL] + [v] keys combination |
| "{CTRL_x}"      | send keycodes for [CONTROL] + [x] keys combination |
| "{CTRL_r}"      | send keycodes for [CONTROL] + [r] keys combination |
| "{CTRL_F1}"     | send keycodes for [CONTROL] + [F1] keys combination |
| "{CTRL_F2}"     | send keycodes for [CONTROL] + [F2] keys combination |
| "{CTRL_F3}"     | send keycodes for [CONTROL] + [F3] keys combination |
| "{CTRL_F4}"     | send keycodes for [CONTROL] + [F4] keys combination |
| "{CTRL_F5}"     | send keycodes for [CONTROL] + [F5] keys combination |
| "{CTRL_F6}"     | send keycodes for [CONTROL] + [F6] keys combination |
| "{CTRL_F7}"     | send keycodes for [CONTROL] + [F7] keys combination |
| "{CTRL_F8}"     | send keycodes for [CONTROL] + [F8] keys combination |
| "{CTRL_F9}"     | send keycodes for [CONTROL] + [F9] keys combination |
| "{CTRL_F10}"    | send keycodes for [CONTROL] + [F10] keys combination |
| "{CTRL_F11}"    | send keycodes for [CONTROL] + [F11] keys combination |
| "{CTRL_F12}"    | send keycodes for [CONTROL] + [F12] keys combination |
| "{TAB}"         | send keycode for [TAB] key |
| "{WIN}"         | send keycode for [Windows] key |
| "{ENTER}"       | send keycode for [Enter] key |
| "{DOWN}"        | send keycode for down arrow key |
| "{UP}"          | send keycode for up arrow key |
| "{LEFT}"        | send keycode for left arrow key |
| "{RIGHT}"       | send keycode for right arrow key |
| "{PAGEUP}"      | send keycode for [Page up] key |
| "{PAGEDOWN}"    | send keycode for [Page down] key |
| "{ECHAP}"       | send keycode for [Escape] key |

### Return
None

### Example

    Send-SpecialKeys "{CTRL_a}"

> select all text in active window

---
##  Send-Keys ($KeysToPress, $Timing)

This function simulates keyboard activity, emitting any keycodes that are not special (look above for the special keys). Combination will not work too, it can’t write “#” or “[“.

### Parameters

| param   | type   | mandatory | description |
|---------|--------|-----------|-------------|
| KeysToPress | string | yes | keycode to send |
| Timing      | int    | no  | delay (in ms) between key press and key release |

### Return

None.

### Example

    Send-Keys ("Your String")

> Your String

---
##  Move-Mouse ($AbsoluteX, $AbsoluteY)

Move the mouse pointer at a given screen absolute coordonates (in pixels)

### Parameters

| param   | type   | mandatory | description |
|---------|--------|-----------|-------------|
| AbsoluteX | int | yes | absolute coordinate on X axis |
| AbsoluteY | int | yes | absolute coordinate on Y axis |

### Return

If the given coordinates are out of bound regarding the current screen resolution, the function return the following error string:
> "WARN" "Absolute position not received ($AbsoluteX, $AbsoluteY)." 

### Example
     Move-Mouse (100, 242)

---
## Set-Active, Set-Active-Maximized

Selects a window from its PID, and activates it.

The function **Set-Active-Maximized** also put the selected window into *maximized* mode

### Parameters

| param   | type   | mandatory | description |
|---------|--------|-----------|-------------|
| ProcessPid | int | yes | Process IDentifier of the process to select |

### Return

None.

### Example

    Set-Active 14393

---
##  PurgeProcess

Kill the calling process (eg. the PowerShell script) but also it child processes (eg. all scripts or executables called by the PowerShell script)

### Parameters

None.

### Return

None.

### Example

    PurgeProcess

---
## ImageSearch

Search an image pattern from it local image pattern database in the visible field of the screen.

The the pattern is not found, a screenshot is taken and automatically uploaded on the registed EON server. Then the function returns an error.

### Parameters

| param   | type   | mandatory | description |
|---------|--------|-----------|-------------|
| Image                | string |  yes             | The image name, composed by "$Image_"[File name without bmp extention] |
| ImageSearchRetries   | int    |  yes             | Maximum attempts to find the image pattern on the screen. Each attempt is execute every **Wait** milliseconds |
| ImageSearchVerbosity | int    |  yes             | possible values : **0** no debug, **1** full debug, **2** save screenshot |
| EonSrv               | string | yes              | FQDN or IP address of EON server where to upload screenshots |
| Wait                 | int    | no (default:250) | delay to wait for (in ms) between each attempt |
| noerror              | int    | no (default:0)   | **0**: capture a screenshot - **1**: don't capture the screenshot |
| variance             | int    | no default:0)    | image variance (range: 0-255) |
| green                | int    | no (default:0)   | **1**: converts image to green monochrome. **0**: keep current color space |

### Return

The function return an array of (x,y) coordinates where the image pattern was found.

In case of the image was not found the array value is (-1,-1) and the script is terminated.

### Example

    $xy = ImageSearch $Image_button_close 10 2 "10.2.12.1" 250 0 30
> $xy = (114,234)

---
##  ImageSearchLowPrecision

This function calls **ImageSearch** (see above) using pre defined  chromatic filters, allowing more errors from the source image.

Common use-case is the digit to click popupar on most banking web applications, where athrough the painted digits always look the same, they are in fact always different with invisibles changes for an human eye.

### Parameters

Parameter are identical to **ImageSearch**. The only difference is for **green** parameter, set to **1**.

---
##  ImageClick ($xy, $xoffset, $yoffset, $type)

Manages a mouse click when an image pattern is found

### Parameters

| param   | type   | mandatory | description |
|---------|--------|-----------|-------------|
| xy      | int array  | yes   | array of int containing the (x,y) coordinates in pixel of the center of the image pattern found |
| xoffset | signed int | yes   | decals the mouse pointer on its X axis by **xoffset** pixels relative to **xy**. The offset is positive to decal on right, negative to decal on left |
| yoffset | signed int | yes   | decals the mouse pointer on its Y axis by **yoffset** pixels relative to **xy**. The offset is positive to decal on down, negative to decal on up |
| type    | string     | yes (default:"left") | mouse button to click on. Valid values are the ones accepted by the function **Click-MouseButton** |

### Return

None.

### Example

    $xy = (123, 234)
    ImageClick ($xy, 0, 0)
> move to mouse to $xy coordinates, then left-click the mouse 

---
##  GetCryptedPass ($string, $useKey )

Store or get a password into/from a encrypted vault file.

* When the function is called with **$string** and optionaly **$useKey** parameter, it encrypts the **string** value and stores the ciphered string into a file stored on the same path than the EOA application script with **.pass** extenstion.
* if **$useKey** switch is triggered, the crypto function will generate an AES hash and use it as salt key for the password cipher function, instead of derivating the salt from the host's GUID. **This is mandatory if you plan to use the EOA scenario elsewhere than the host where the scenario was created !**
* When the function is called without any arguments, it search for a **.pass** file and decrypt the stored password.

### Parameters

| param   | type   | mandatory | description |
|---------|--------|-----------|-------------|
| string  | string | no | the string to encrypt |
| useKey  | switch | no | generates an AES key to use as cipher salt |

### Return

The function returns a string containing the password string. If an error occured, the function return a **null** value

### Examples

* This creates the **.pass** and **.key** files with the encrypted password, then return the clear password string
    GetCryptedPass "password", 1
> password

* This returns the clear password string, if **.pass** file exists
    GetCryptedPass
> password

---
##  SetScreenResolution ($resX, $resY, $debug)

Sets the screen resolution.
With EOA, it is important to force the screen resolution to ensure the desktop look n'feel is always the same as EOA tries to find image patterns on the screen to identify fields to interact with.

### Parameters

| param   | type   | mandatory | description |
|---------|--------|-----------|-------------|
| resX  | int | yes             | X screen resolution (1280, 1980, ...) |
| resY  | int | yes             | Y screen resolution (1024, 1200, ...) |
| debug | int | yes (default:2) | valid values : 0, 1, 2 |

### Return

Return nothing, but the function call trows an exception if it failed to set the screen resolution to the given values

### Example

    SetScreenResolution 1920 1080 0

---
##  ImageNotExist

Check if an given image exists.

### Parameters

| param   | type   | mandatory | description |
|---------|--------|-----------|-------------|
| ImageToFind | string | yes | Image pattern to find, see **ImageSearch** for details |
| Retries     | string | yes | number of retries before fail. Earch retry is postponed by 250 ms |

### Return

Returns a **bool** value:
* **0**: image exist
* **1**: image does *not* exist

### Example

    ImageNotExist $Image_click_button 20
> tries 20 times to find for image patten click_button.bmp