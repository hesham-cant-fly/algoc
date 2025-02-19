
import { Name } from "./common.ts";
import * as VectorGen from "./Vector.ts";

const that = {
    VectorGen
};

const things: Record<any, { out: string, data: Name[] }> = {
    VectorGen: {
        out: "Vector",
        data: [
            {
                tp: "Token",
                san: "Token"
            }
        ]
    }
};

for (let i in things) {
    that[i].make(things[i].data, things[i].out)
}
