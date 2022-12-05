import { Machine } from '../../../app/frontend/src/javascript/models/machine';

const machines: Array<Machine> = [
  {
    id: 1,
    name: 'Laser cutter',
    description: 'EPILOG Legend 36EXT',
    spec: 'Power: 40W, Working area: 914 x 609mm, Maximum material thickness: 305mm',
    slug: 'laser-cutter',
    disabled: false
  },
  {
    id: 2,
    name: '3D printer',
    description: 'Ultimaker 2',
    spec: 'Maximum working area: 210 x 210 x 220mm, Mechanical resolution: 0.02mm',
    slug: '3d-printer',
    disabled: false
  }
];

export default machines;
