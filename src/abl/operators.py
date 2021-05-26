from textwrap import wrap

from snek5000.operators import Operators as _Operators


class OperatorsABL(_Operators):
    @staticmethod
    def _complete_params_with_default(params):
        """This static method is used to complete the *params.oper* container."""
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
                if not isinstance(coords, str):
                    try:
                        coords = " ".join(str(i) for i in coords)
                    except TypeError:
                        raise TypeError(
                            "params.oper.coords_{x,y,z} should be either "
                            "a string or an iterable"
                        )

                del grid_info[f"{ax}0 {ax}1 ratio"]
                # hardcoded coordinates
                grid_info[f"{ax} coords"] = "\n".join(wrap(coords, 72)) + " " * 4

                str_nb_elem += str(nax) + " "
            else:
                grid_info.move_to_end(f"{ax}0 {ax}1 ratio")
                str_nb_elem += str(-nax) + " "

        grid_info["nelx nely nelz"] = str_nb_elem
        grid_info.move_to_end("Velocity BCs")

        if self.params.oper.boundary_scalars:
            grid_info.move_to_end("Temperature / scalar BCs")

        return info
