import { IModule } from "angular";

interface IApplication {
    Components: IModule,
    Services: IModule,
    Controllers: IModule,
    Filters: IModule,
    Directives: IModule
}

declare var Application: IApplication;
export default Application;

