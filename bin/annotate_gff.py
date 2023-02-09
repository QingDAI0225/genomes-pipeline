#!/usr/bin/env python3

# This file is part of MGnify genome analysis pipeline.
#
# MGnify genome analysis pipeline is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# MGnify genome analysis pipeline is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with MGnify genome analysis pipeline. If not, see <https://www.gnu.org/licenses/>.

import argparse
import sys
import os


def get_iprs(ipr_annot):
    iprs = {}
    with open(ipr_annot, "r") as f:
        for line in f:
            cols = line.strip().split("\t")
            protein = cols[0]
            if protein not in iprs:
                iprs[protein] = [set(), set()]
            if cols[3] == "Pfam":
                pfam = cols[4]
                iprs[protein][0].add(pfam)
            if len(cols) > 12:
                ipr = cols[11]
                iprs[protein][1].add(ipr)
    return iprs


def get_eggnog(eggnot_annot):
    eggnogs = {}
    with open(eggnot_annot, "r") as f:
        for line in f:
            line = line.rstrip()
            cols = line.split("\t")
            if line.startswith("#"):
                eggnog_fields = get_eggnog_fields(line)
            else:
                protein = cols[0]
                eggnog = [cols[1]]
                try:
                    cog = cols[eggnog_fields["cog_func"]]
                    cog = cog.split()
                    if len(cog) > 1:
                        cog = ["R"]
                except:
                    cog = ["NA"]
                kegg = cols[eggnog_fields["KEGG_ko"]].split(",")
                eggnogs[protein] = [eggnog, cog, kegg]
    return eggnogs


def get_eggnog_fields(line):
    cols = line.strip().split("\t")
    print(cols)
    if cols[8] == "KEGG_ko" and cols[15] == "CAZy":
        eggnog_fields = {"KEGG_ko": 8, "cog_func": 20}
    elif cols[11] == "KEGG_ko" and cols[18] == "CAZy":
        eggnog_fields = {"KEGG_ko": 11, "cog_func": 6}
    else:
        sys.exit("Cannot parse eggNOG - unexpected field order or naming")
    return eggnog_fields


def add_gff(in_gff, eggnog_file, ipr_file):
    eggnogs = get_eggnog(eggnog_file)
    iprs = get_iprs(ipr_file)
    added_annot = {}
    out_gff = []
    with open(in_gff, "r") as f:
        for line in f:
            line = line.strip()
            if line[0] != "#":
                cols = line.split("\t")
                if len(cols) == 9:
                    annot = cols[8]
                    protein = annot.split(";")[0].split("=")[-1]
                    added_annot[protein] = {}
                    try:
                        eggnogs[protein]
                        pos = 0
                        for a in eggnogs[protein]:
                            pos += 1
                            if a != [""] and a != ["NA"]:
                                if pos == 1:
                                    added_annot[protein]["eggNOG"] = a
                                elif pos == 2:
                                    added_annot[protein]["COG"] = a
                                elif pos == 3:
                                    added_annot[protein]["KEGG"] = a
                    except:
                        pass
                    try:
                        iprs[protein]
                        pos = 0
                        for a in iprs[protein]:
                            pos += 1
                            a = list(a)
                            if a != [""] and a:
                                if pos == 1:
                                    added_annot[protein]["Pfam"] = a
                                elif pos == 2:
                                    added_annot[protein]["InterPro"] = a
                    except:
                        pass
                    for a in added_annot[protein]:
                        value = added_annot[protein][a]
                        if type(value) is list:
                            value = ",".join(value)
                        cols[8] = "{};{}={}".format(cols[8], a, value)
                    line = "\t".join(cols)
            out_gff.append(line)
    return out_gff


def get_rnas(ncrnas_file):
    ncrnas = {}
    counts = 0
    with open(ncrnas_file, "r") as f:
        for line in f:
            if not line.startswith("#"):
                cols = line.strip().split()
                counts += 1
                contig = cols[3]
                locus = "{}_ncRNA{}".format(contig, counts)
                product = " ".join(cols[26:])
                model = cols[2]
                strand = cols[11]
                if strand == "+":
                    start = int(cols[9])
                    end = int(cols[10])
                else:
                    start = int(cols[10])
                    end = int(cols[9])
                ncrnas.setdefault(contig, list()).append(
                    [locus, start, end, product, model, strand]
                )
                # if contig not in ncrnas:
                #    ncrnas[contig] = [[locus, start, end, product, model, strand]]
                # else:
                #    ncrnas[contig].append([locus, start, end, product, model, strand])
    return ncrnas


def add_ncrnas_to_gff(gff_outfile, ncrnas, res):
    gff_out = open(gff_outfile, "w")
    added = set()
    for line in res:
        cols = line.strip().split("\t")
        if line[0] != "#" and len(cols) == 9:
            if cols[2] == "CDS":
                contig = cols[0]
                if contig in ncrnas:
                    for c in ncrnas[contig]:
                        locus = c[0]
                        start = str(c[1])
                        end = str(c[2])
                        product = c[3]
                        model = c[4]
                        strand = c[5]
                        if locus not in added:
                            added.add(locus)
                            annot = [
                                "ID=" + locus,
                                "inference=Rfam:14.6",
                                "locus_tag=" + locus,
                                "product=" + product,
                                "rfam=" + model,
                            ]
                            annot = ";".join(annot)
                            newLine = [
                                contig,
                                "INFERNAL:1.1.2",
                                "ncRNA",
                                start,
                                end,
                                ".",
                                strand,
                                ".",
                                annot,
                            ]
                            gff_out.write("\t".join(newLine) + "\n")
                gff_out.write("{}\n".format(line))
        #            else:
        #                gff_out.write("{}\n".format(line))
        else:
            gff_out.write("{}\n".format(line))
    gff_out.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Add functional annotation to GFF file",
    )
    parser.add_argument(
        "-g",
        dest="gff_input",
        required=True,
        help="GFF input file",
    )
    parser.add_argument(
        "-e",
        dest="eggnong",
        help="eggnog annontations for the clutser repo",
        required=True,
    )
    parser.add_argument(
        "-i",
        dest="ips",
        help="InterproScan annontations results for the cluster rep",
        required=True,
    )
    parser.add_argument("-r", dest="rfam", help="Rfam results", required=True)
    parser.add_argument("-o", dest="outfile", help="Outfile name", required=False)

    args = parser.parse_args()

    gff = args.gff_input

    extended_gff = add_gff(
        in_gff=gff,
        eggnog_file=args.eggnong,
        ipr_file=args.ips,
    )

    ncRNAs = get_rnas(args.rfam)

    if not args.outfile:
        outfile = gff.split(".gff")[0] + "_annotated.gff"
    else:
        outfile = args.outfile

    add_ncrnas_to_gff(outfile, ncRNAs, extended_gff)
