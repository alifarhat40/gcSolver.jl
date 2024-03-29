const active_species_IDX = [8, 9, 15, 16, 19, 22, 25, 28]
const Nspecies = 62 # number of complexes in surface + endosome + free ligand
const halfL = 28 # number of complexes on surface alone
const internalV = 623.0 # Same as that used in TAM model
const internalFrac = 0.5 # Same as that used in TAM model
const recIDX = [1, 2, 3, 10, 17, 20, 23, 26]

const Nparams = 30 # number of unknowns for the full model
const NIL2params = 10 # number of unknowns for the IL2 model
const Nlig = 6 # Number of ligands
const kfbnd = 0.60 # Assuming on rate of 10^7 M-1 sec-1

# p[1:4] is kfwd, k1rev, k2rev, k4rev
# p[5:8] is k5rev, k10rev, k11rev, k13rev
# p[9:12] is k14rev, k16rev, k17rev, k22rev
# p[13:14] is k23rev, k24rev

function dYdT(du, u, p::Vector, ILs)
    # IL2Ra, IL2Rb, gc, IL2_IL2Ra, IL2_IL2Rb, IL2_IL2Ra_IL2Rb, IL2_IL2Ra_gc, IL2_IL2Rb_gc, IL2_IL2Ra_IL2Rb_gc
    # IL15Ra, IL15_IL15Ra, IL15_IL2Rb, IL15_IL15Ra_IL2Rb, IL15_IL15Ra_gc, IL15_IL2Rb_gc, IL15_IL15Ra_IL2Rb_gc

    # IL2/15
    for i in 0:1
        pp = p[1 + i*6:8 + i*6]
        k12rev = pp[2] * pp[7] / pp[3] # Detailed balance
        k8rev = pp[6] * k12rev / pp[5] # Detailed balance
        k9rev = pp[6] * pp[7] / pp[4] # Detailed balance

        du[2] += -kfbnd * u[2] * ILs[i+1] + pp[3] * u[5 + 7*i] - p[1] * u[2] * u[7 + 7*i] + k9rev * u[9 + 7*i] - p[1] * u[2] * u[4 + 7*i] + pp[7] * u[6 + 7*i];
        du[3] += -p[1] * u[5 + 7*i] * u[3] + p[5 + 7*i] * u[8 + 7*i] - p[1] * u[4 + 7*i] * u[3] + p[4 + 7*i] * u[7 + 7*i] - p[1] * u[6 + 7*i] * u[3] + p[6 + 7*i] * u[9 + 7*i];
        du[1 + 9*i] = -kfbnd * u[1 + 9*i] * ILs[i+1] + pp[2] * u[4 + 7*i] - p[1] * u[1 + 9*i] * u[8 + 7*i] + k8rev * u[9 + 7*i] - p[1] * u[1 + 9*i] * u[5 + 7*i] + k12rev * u[6 + 7*i];
        du[4 + 7*i] = -p[1] * u[4 + 7*i] * u[2] + pp[7] * u[6 + 7*i] - p[1] * u[4 + 7*i] * u[3] + pp[4] * u[7 + 7*i] + kfbnd * ILs[i+1] * u[1 + 9*i] - pp[2] * u[4 + 7*i]
        du[5 + 7*i] = -p[1] * u[5 + 7*i] * u[1 + 9*i] + k12rev * u[6 + 7*i] - p[1] * u[5 + 7*i] * u[3] + p[5 + 7*i] * u[8 + 7*i] + kfbnd * ILs[i+1] * u[2] - pp[3] * u[5 + 7*i]
        du[6 + 7*i] = -p[1] * u[6 + 7*i] * u[3] + pp[6] * u[9 + 7*i] + p[1] * u[4 + 7*i] * u[2] - pp[7] * u[6 + 7*i] + p[1] * u[5 + 7*i] * u[1 + 9*i] - k12rev * u[6 + 7*i]
        du[9 + 7*i] = p[1] * u[8 + 7*i] * u[1 + 9*i] - k8rev * u[9 + 7*i] + p[1] * u[7 + 7*i] * u[2] - k9rev * u[9 + 7*i] + p[1] * u[6 + 7*i] * u[3] - pp[6] * u[9 + 7*i]
        du[7 + 7*i] = -p[1] * u[7 + 7*i] * u[2] + k9rev * u[9 + 7*i] + p[1] * u[4 + 7*i] * u[3] - pp[4] * u[7 + 7*i]
        du[8 + 7*i] = -p[1] * u[8 + 7*i] * u[1 + 9*i] + k8rev * u[9 + 7*i] + p[1] * u[3] * u[5 + 7*i] - pp[5] * u[8 + 7*i]
    end

    for i in 0:3
        ij = 17 + i*3
        du[3] += - p[1] * u[3] * u[ij+1] + p[15 + 2*i] * u[ij+2];
        du[ij] = -kfbnd * u[ij] * ILs[3 + i] + p[14 + 2*i] * u[ij+1];
        du[ij+1] = kfbnd * u[ij] * ILs[3 + i] - p[14 + 2*i] * u[ij+1] - p[1] * u[3] * u[ij+1] + p[15 + 2*i] * u[ij+2];
        du[ij+2] = p[1] * u[3] * u[ij+1] - p[15 + 2*i] * u[ij+2];
    end
    return nothing
end


function fullModel(du, u, pSurf, pEndo, trafP, ILs)
    fill!(du, 0.0)

    # Calculate cell surface and endosomal reactions
    dYdT(du, u, pSurf, ILs)
    dYdT(view(du, halfL+1:2*halfL), view(u, halfL+1:2*halfL), pEndo, view(u, halfL*2:Nspecies))

    # Handle endosomal ligand balance.
    # Must come before trafficking as we only calculate this based on reactions balance
    du[57] = -sum(view(du, halfL+4:halfL+9)) / internalV
    du[58] = -sum(view(du, halfL+11:halfL+16)) / internalV
    du[59] = -sum(view(du, halfL+18:halfL+19)) / internalV
    du[60] = -sum(view(du, halfL+21:halfL+22)) / internalV
    du[61] = -sum(view(du, halfL+24:halfL+25)) / internalV
    du[62] = -sum(view(du, halfL+27:halfL+28)) / internalV

    # Actually calculate the trafficking
    for ii in range(1, stop=halfL)
        if findfirst(isequal(ii), active_species_IDX) != nothing
            du[ii] += -u[ii]*(trafP[1] + trafP[2]) # Endocytosis
            du[ii+halfL] += u[ii]*(trafP[1] + trafP[2])/internalFrac - trafP[5]*u[ii+halfL] # Endocytosis, degradation
        else
            du[ii] += -u[ii]*trafP[1] + trafP[4]*(1.0 - trafP[3])*u[ii+halfL]*internalFrac # Endocytosis, recycling
            du[ii+halfL] += u[ii]*trafP[1]/internalFrac - trafP[4]*(1.0 - trafP[3])*u[ii+halfL] - (trafP[5]*trafP[3])*u[ii+halfL] # Endocytosis, recycling, degradation
        end
    end

    # Expression: IL2Ra, IL2Rb, gc, IL15Ra, IL7Ra, IL9R, IL4Ra, IL21Ra
    du[recIDX] += trafP[6:13]

    # Degradation does lead to some clearance of ligand in the endosome
    for ii in range(halfL*2 + 1, stop=halfL*2 + 6)
        du[ii] -= u[ii] * trafP[5]
    end

    return nothing
end


# Initial autocrine condition - DONE
function solveAutocrine(r)
    # r is endo, activeEndo, sortF, kRec, kDeg, Rexpr*8
    y0 = zeros(eltype(r), Nspecies)

    # Check if we're working with the no trafficking model
    if r[1] == 0.0
        y0[recIDX] = view(r, range(5, length=length(recIDX)))
        return y0
    end

    # Expand out trafficking terms
    kRec = r[4] * (1 - r[3])
    kDeg = r[5] * r[3]

    # Assuming no autocrine ligand, so can solve steady state
    # Add the species
    y0[recIDX .+ halfL] = r[range(5, length=length(recIDX))] / kDeg / internalFrac
    y0[recIDX] = (r[range(5, length=length(recIDX))] + kRec*y0[recIDX .+ halfL]*internalFrac)/r[1]

    return y0
end
