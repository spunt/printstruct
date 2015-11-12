# printstruct

MATLAB tool to recursively print hierarchical outline of structure contents. This is a minor adaptation of the File Exchange contribution "Structure outline" written by B. Roossien and available [here](http://mathworks.com/matlabcentral/fileexchange/13500-structure-outline). 

#### USAGE: pS = printstruct(S, varargin)
          
Run `printstruct` with no args prints help and shows default VARARGINs

---

### NECESSARY INPUT
- **S**
  + structure variable to print
  
---

### OPTIONAL OUTPUT
- **pS**
  + cell array containing printed structure
  + if defined, `printstruct` will not display result in command window
  
---

### VARARGIN [entered as 'name', value pairs]

|      NAME      |                      DESCRIPTION                      |
|----------------|-------------------------------------------------------|
| nlevels        | N levels to print. If negative, all levels printed.   |
| nindent        | number of tab indents for each line of printed struct |
| structname     | top level name (if empty, variable name will be used) |
| printcontents  | flag to print field values/contents as well           |
| maxarraylength | for fields with array data, max length of values to print. Values of a 2-D (m,n) array are printed if the number of elements (m x n) is smaller or equal to maxarraylength. This is ignored if printvalues is 0.        |

- run `printstruct` w/no arguments to see default values

---

### EXAMPLES

    pS = printstruct(S, 'maxarray', 100); 

    printstruct(S, 'nlevels', 2, 'printcontents', 0, 'nindent', 3)

