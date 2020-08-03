from snek5000.operators import Operators as _Operators


class OperatorsABL(_Operators):
    @staticmethod
    def _complete_params_with_default(params):
        """This static method is used to complete the *params.oper* container.
        """
        _Operators._complete_params_with_default(params)
        params.oper._set_attribs({"coords_x": "", "coords_y": "", "coords_z": ""})

    def info_box(self, comments=""):
        info = super().info_box(comments)
        info["comments"] += "Modified by abl.operators.OperatorsABL"

        grid_info = info["grid_info"]
        str_nb_elem = ""

        for ax in "xyz":
            # eg: params.oper.coords_y
            coords = getattr(self.params.oper, f"coords_{ax}")

            # eg: params.oper.ny
            nax = getattr(self.params.oper, f"n{ax}")

            if coords:
                del grid_info[f"{ax}0 {ax}1 ratio"]
                grid_info[f"    {ax} coords"] = coords  # hardcoded coordinates

                str_nb_elem += str(nax) + " "
            else:
                str_nb_elem += str(-nax) + " "

        grid_info["nelx nely nelz"] = str_nb_elem

        return info
